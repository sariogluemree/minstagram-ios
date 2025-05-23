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
        case all = "all"
        
        var url: String {
            return APIEndpoints.baseURL + "users/" + self.rawValue
        }
    }
    
    enum forFollow: String {
        case follow = "follow"
        case unfollow = "unfollow"
        case following = "following"
        case followers = "followers"
        case isFollowing = "isFollowing"
        
        var url: String {
            return APIEndpoints.baseURL + "follows/" + self.rawValue
        }
    }
    
    enum forUpload : String {
        case upload = "upload"
        
        var url: String {
            return APIEndpoints.baseURL + self.rawValue
        }
    }
    
    enum forPost: String {
        case cud = "/"
        case post = "/post"
        case forUser = "/forUser"
        case feed = "/feed"
        
        var url : String {
            return APIEndpoints.baseURL + "posts" + self.rawValue
        }
    }
    
    enum forComment: String {
        case create = "create"
        case getAll = "getAll"
        case delete = "delete"
        
        var url: String {
            return APIEndpoints.baseURL + "comments/" + self.rawValue
        }
    }
    
    enum forLike: String {
        case like = "like"
        case getAll = "getAll"
        case unlike = "unlike"
        
        var url: String {
            return APIEndpoints.baseURL + "likes/" + self.rawValue
        }
    }
    
    enum forSavedPost: String {
        case save = "save"
        case getAll = "getAll"
        case unsave = "unsave"
        
        var url: String {
            return APIEndpoints.baseURL + "savedPosts/" + self.rawValue
        }
    }
    
    enum forNotification: String {
        case get = "/"
        case seen = "/seen"
        
        var url: String {
            return APIEndpoints.baseURL + "notifications" + self.rawValue
        }
    }

}
