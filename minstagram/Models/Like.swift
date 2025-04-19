//
//  Like.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 19.04.2025.
//

import Foundation

struct Like: Codable {
    let id: String
    let user: PostUser
    let post: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user = "userId"
        case post = "postId"
    }
}
