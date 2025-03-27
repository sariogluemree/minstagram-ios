//
//  Post.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 5.03.2025.
//

import Foundation

struct Post: Codable {
    let id: String
    let userId: String
    let username: String
    let userProfileImageUrl: String?
    let imageUrl: String
    let caption: String?
    let likeCount: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case username
        case userProfileImageUrl
        case imageUrl
        case caption
        case likeCount
        case createdAt
    }
}
