//
//  SavedPostEndpoint.swift
//  minstagram
//

import Foundation

enum SavedPostEndpoint: Endpoint {
    case save(postId: String)
    /// Backend `DELETE` + JSON body bekliyor.
    case unsave(postId: String)
    /// → `[Post]`
    case getAll(userId: String)

    var path: String {
        switch self {
        case .save:               return "savedPosts/save"
        case .unsave:             return "savedPosts/unsave"
        case .getAll(let userId): return "savedPosts/getAll/\(userId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .save:   return .post
        case .unsave: return .delete
        case .getAll: return .get
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .save(let postId), .unsave(let postId): return PostIdRequest(postId: postId)
        case .getAll:                                return nil
        }
    }
}
