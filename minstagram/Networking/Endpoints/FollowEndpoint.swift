//
//  FollowEndpoint.swift
//  minstagram
//

import Foundation

enum FollowEndpoint: Endpoint {
    case follow(userId: String)
    case unfollow(userId: String)
    /// Backend route param'ı `:userId` adında olsa da **username** ile arama yapıyor. → `[PostUser]`
    case followers(username: String)
    /// → `IsFollowingResponse`
    case isFollowing(userId: String)

    var path: String {
        switch self {
        case .follow:                  return "follows/follow"
        case .unfollow:                return "follows/unfollow"
        case .followers(let username): return "follows/followers/\(username)"
        case .isFollowing:             return "follows/isFollowing"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .follow, .unfollow: return .post
        default:                 return .get
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
        default:                                         return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .followers: return false
        default:         return true
        }
    }
}
