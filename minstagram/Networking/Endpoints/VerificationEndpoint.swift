//
//  VerificationEndpoint.swift
//  minstagram
//

import Foundation

enum VerificationEndpoint: Endpoint {
    case sendCode(email: String)
    case verify(email: String, code: String)

    var path: String {
        switch self {
        case .sendCode: return "verifications/send-verification-code"
        case .verify:   return "verifications/verify-email"
        }
    }

    var method: HTTPMethod { .post }

    var body: (any Encodable)? {
        switch self {
        case .sendCode(let email):         return EmailRequest(email: email)
        case .verify(let email, let code): return VerifyEmailRequest(email: email, code: code)
        }
    }

    var requiresAuth: Bool { false }
}
