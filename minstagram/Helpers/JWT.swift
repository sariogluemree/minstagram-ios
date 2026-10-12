//
//  JWT.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 20.03.2025.
//

import Foundation
import JWTDecode

class JWT {
    
    //deneme
    
    static let shared = JWT()
    private init() {}
    
    func isTokenExpired(_ token: String) -> Bool {
        do {
            let jwt = try decode(jwt: token)
            if let expDate = jwt.expiresAt {
                print("expDate: \(expDate)")
                return expDate < Date() // Şu anki tarihten eskiyse token süresi dolmuş
            }
        } catch {
            return true // Decode edilemezse expired kabul et
        }
        return true
    }
    
}
