//
//  UserEndpoint.swift
//  minstagram
//

import Foundation

enum UserEndpoint: Endpoint {
    /// `?type=public` → `UserDetail`
    case profile(username: String)
    /// `?type=post` → `PostUser`
    case postProfile(username: String)
    /// → `[PostUser]`
    case all
    /// → `UserDetail`
    case update(UpdateProfileRequest)

    var path: String {
        switch self {
        case .profile(let username),
             .postProfile(let username): return "users/profile/\(username)"
        case .all:                       return "users/all"
        case .update:                    return "users/update"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .update: return .put
        default:      return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .profile:     return [URLQueryItem(name: "type", value: "public")]
        case .postProfile: return [URLQueryItem(name: "type", value: "post")]
        default:           return nil
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .update(let request): return request
        default:                   return nil
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .update: return true
        default:      return false
        }
    }
}
