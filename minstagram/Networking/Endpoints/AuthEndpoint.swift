//
//  AuthEndpoint.swift
//  minstagram
//

import Foundation

enum AuthEndpoint: Endpoint {
    case login(LoginRequest)
    case register(RegisterRequest)

    var path: String {
        switch self {
        case .login:    return "users/login"
        case .register: return "users/register"
        }
    }

    var method: HTTPMethod { .post }

    var body: (any Encodable)? {
        switch self {
        case .login(let request):    return request
        case .register(let request): return request
        }
    }

    var requiresAuth: Bool { false }
}
