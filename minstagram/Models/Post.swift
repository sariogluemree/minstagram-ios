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
    var caption: String?
    let tags: [Tag]
    let createdAt: String
    let user: PostUser
    var comments: [Comment]
    var likeCount: Int
    var isLiked: Bool
    var isSaved: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageUrl
        case caption
        case tags
        case createdAt
        case user = "userId"
        case comments
        case likeCount
        case isLiked
        case isSaved
    }
}
