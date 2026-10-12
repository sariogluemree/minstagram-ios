//
//  PostEndpoint.swift
//  minstagram
//

import Foundation

enum PostEndpoint: Endpoint {
    /// → `Post`
    case create(CreatePostRequest)
    case delete(id: String)
    /// → `Post`
    case detail(id: String)
    /// → `[Post]`
    case forUser(userId: String)
    /// → `[Post]`
    case feed

    var path: String {
        switch self {
        case .create:              return "posts"
        case .delete(let id):      return "posts/\(id)"
        case .detail(let id):      return "posts/post/\(id)"
        case .forUser(let userId): return "posts/forUser/\(userId)"
        case .feed:                return "posts/feed"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .delete: return .delete
        default:      return .get
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .create(let request): return request
        default:                   return nil
        }
    }
}
