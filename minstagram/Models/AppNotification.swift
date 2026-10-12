//
//  AppNotification.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 21.05.2025.
//

import Foundation

enum NotificationType: String, Codable {
    case follow
    case like
    case comment
    case tag
}

struct AppNotification: Codable {
    let id: String
    let type: NotificationType
    let sender: PostUser
    let postId: String?
    let comment: Comment?
    var seen: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case sender = "senderId"
        case postId
        case comment = "commentId"
        case seen
        case createdAt
    }
}
