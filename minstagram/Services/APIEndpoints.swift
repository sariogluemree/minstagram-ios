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
    
    enum forUser: String {
        case profile = "profile"
        case update = "update"
        case delete = "delete"
        
        var url: String {
            return APIEndpoints.baseURL + "users/" + self.rawValue
        }
    }
    
    enum forFollow: String {
        case follow = "follow"
        case unfollow = "unfollow"
        case following = "following"
        case followers = "followers"
        
        var url: String {
            return APIEndpoints.baseURL + "follows/" + self.rawValue
        }
    }
    
    enum forPost: String {
        case all = "/"
        var url : String {
            return APIEndpoints.baseURL + "posts" + self.rawValue
        }
    }

}
