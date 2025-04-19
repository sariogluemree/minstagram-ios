//
//  Comment.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 16.04.2025.
//

import Foundation

struct Comment: Codable {
    let id: String
    let text: String
    let user: PostUser
    let post: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case text
        case user = "userId"
        case post = "postId"
        case createdAt
    }
}
