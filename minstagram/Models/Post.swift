//
//  Post.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 5.03.2025.
//

import Foundation

struct Post: Codable {
    let id: String
    let imageUrl: String
    let caption: String?
    let tags: [Tag]
    let createdAt: String
    let user: PostUser
    let comments: [Comment]
    let likeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageUrl
        case caption
        case tags
        case createdAt
        case user
        case comments
        case likeCount
    }
}

struct Comment: Codable {
    let id: String
    let text: String
    let user: PostUser
    let createdAt: String
}
