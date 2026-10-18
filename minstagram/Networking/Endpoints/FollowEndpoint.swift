//
//  FollowEndpoint.swift
//  minstagram
//

import Foundation

enum FollowEndpoint: Endpoint {
    case follow(userId: String)
    case unfollow(userId: String)
    case removeFollower(userId: String)
    /// Backend route param'ı `:userId` adında olsa da **username** (veya id) ile arama yapıyor. → `[PostUser]`
    case followers(username: String)
    /// → `[PostUser]`
    case following(username: String)
    /// → `IsFollowingResponse`
    case isFollowing(userId: String)

    var path: String {
        switch self {
        case .follow:                  return "follows/follow"
        case .unfollow:                return "follows/unfollow"
        case .removeFollower:          return "follows/removeFollower"
        case .followers(let username): return "follows/followers/\(username)"
        case .following(let username): return "follows/following/\(username)"
        case .isFollowing:             return "follows/isFollowing"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .follow, .unfollow, .removeFollower: return .post
        default:                                  return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .isFollowing(let userId): return [URLQueryItem(name: "followingId", value: userId)]
        default:                       return nil
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .follow(let userId), .unfollow(let userId): return FollowRequest(followingId: userId)
        case .removeFollower(let userId):                return RemoveFollowerRequest(followerId: userId)
        default:                                         return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .followers, .following: return false
        default:                     return true
        }
    }
}
