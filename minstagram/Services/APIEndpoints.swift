//
//  APIEndpoints.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 2.03.2025.
//


//
//  APIEndpoints.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 2.03.2025.
//

import Foundation

struct APIEndpoints {
    
    private static let baseURL = "http://localhost:5001/api/"
    
    enum forAuth: String {
        case login = "login"
        case register = "register"

        var url: String {
            return APIEndpoints.baseURL + "users/" + self.rawValue
        }
    }
    
    enum forEmail: String {
        case send = "send-verification-code"
        case verify = "verify-email"
        
        var url: String {
            return APIEndpoints.baseURL + "verifications/" + self.rawValue
        }
    }

}
