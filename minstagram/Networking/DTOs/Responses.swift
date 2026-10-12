//
//  Responses.swift
//  minstagram
//

import Foundation

struct LoginResponse: Decodable {
    let token: String
    let user: UserDetail
}

struct RegisterResponse: Decodable {
    let newUser: UserDetail
    let registerMessage: String
}

struct MessageResponse: Decodable {
    let message: String
}

struct IsFollowingResponse: Decodable {
    let isFollowing: Bool
}

struct MarkSeenResponse: Decodable {
    let success: Bool
}

struct HasUnseenResponse: Decodable {
    let hasUnseen: Bool
}

struct UploadResponse: Decodable {
    let url: String
}
