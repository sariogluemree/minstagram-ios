//
//  CommentEndpoint.swift
//  minstagram
//

import Foundation

enum CommentEndpoint: Endpoint {
    /// → `Comment`
    case create(postId: String, text: String)

    var path: String {
        switch self {
        case .create: return "comments/create"
        }
    }

    var method: HTTPMethod { .post }

    var body: (any Encodable)? {
        switch self {
        case .create(let postId, let text): return CreateCommentRequest(postId: postId, text: text)
        }
    }
}
