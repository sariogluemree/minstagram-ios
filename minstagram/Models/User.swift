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

protocol User {
    var id: String { get }
}

struct UserDetail: User, Codable {
    let id: String
    var username: String
    var profilePhoto: String
    var name: String
    var bio: String
    var postsCount: Int
    var followersCount: Int
    var followingCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case profilePhoto
        case name
        case bio
        case postsCount
        case followersCount
        case followingCount
    }
}

struct PostUser: User, Codable {
    let id: String
    let username: String
    let profilePhoto: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case profilePhoto
    }
}
