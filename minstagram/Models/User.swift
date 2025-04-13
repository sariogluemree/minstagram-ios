//
//  User.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 2.03.2025.
//

import Foundation

enum UserProfile {
    case postProfile(PostUser)
    case publicProfile(UserDetail)
}

struct UserDetail: Codable {
    let id: String
    let username: String
    var profilePhoto: String?
    var name: String?
    var bio: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case profilePhoto
        case name
        case bio
    }
}

struct PostUser: Codable {
    let id: String
    let username: String
    let profilePhoto: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case profilePhoto
    }
}
