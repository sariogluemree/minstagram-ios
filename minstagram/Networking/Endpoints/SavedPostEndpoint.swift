//
//  SavedPostEndpoint.swift
//  minstagram
//

import Foundation

enum SavedPostEndpoint: Endpoint {
    case save(postId: String)
    /// Backend `DELETE` + JSON body bekliyor.
    case unsave(postId: String)

    var path: String {
        switch self {
        case .save:   return "savedPosts/save"
        case .unsave: return "savedPosts/unsave"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .save:   return .post
        case .unsave: return .delete
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .save(let postId), .unsave(let postId): return PostIdRequest(postId: postId)
        }
    }
}
