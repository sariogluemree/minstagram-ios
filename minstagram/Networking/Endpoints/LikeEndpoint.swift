//
//  LikeEndpoint.swift
//  minstagram
//

import Foundation

enum LikeEndpoint: Endpoint {
    case like(postId: String)
    /// Backend `DELETE` + JSON body bekliyor.
    case unlike(postId: String)

    var path: String {
        switch self {
        case .like:   return "likes/like"
        case .unlike: return "likes/unlike"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .like:   return .post
        case .unlike: return .delete
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .like(let postId), .unlike(let postId): return PostIdRequest(postId: postId)
        }
    }
}
