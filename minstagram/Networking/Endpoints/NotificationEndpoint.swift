//
//  NotificationEndpoint.swift
//  minstagram
//

import Foundation

enum NotificationEndpoint: Endpoint {
    /// → `[AppNotification]`
    case list
    /// → `MarkSeenResponse`
    case markSeen(id: String)
    /// → `HasUnseenResponse`
    case hasUnseen

    var path: String {
        switch self {
        case .list:             return "notifications"
        case .markSeen(let id): return "notifications/seen/\(id)"
        case .hasUnseen:        return "notifications/has-unseen"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .markSeen: return .post
        default:        return .get
        }
    }
}
