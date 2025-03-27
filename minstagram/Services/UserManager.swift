//
//  UserManager.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 8.03.2025.
//

import Foundation

class UserManager {
    static let shared = UserManager()
    var activeUser: User?
    private init() {}
    
    func getActiveUser() {
        if let userData = UserDefaults.standard.data(forKey: "activeUser") {
            do {
                let loggedInUser = try JSONDecoder().decode(User.self, from: userData)
                UserManager.shared.activeUser = loggedInUser
            } catch {
                print("Decoding hatası: \(error.localizedDescription)")
            }
        }
    }
    
    func getNewRegisteredUserName() -> String? {
        guard let userData = UserDefaults.standard.data(forKey: "newUser") else {
            return nil
        }
        do {
            let registeredUser = try PropertyListDecoder().decode(User.self, from: userData)
            return registeredUser.username
        } catch {
            print("Decoding error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func register(user: User) {
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: "newUser")
        }
    }
    
    func login(tokenData: Data, user: User) {
        KeychainHelper.shared.save(tokenData, service: "com.minstagram.auth", account: "userToken")
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: "activeUser")
        }
        activeUser = user
        print(activeUser?.username ?? "user")
    }
    
    func logOut() {
        activeUser = nil
        UserDefaults.standard.removeObject(forKey: "newUser")
        UserDefaults.standard.removeObject(forKey: "activeUser")
        KeychainHelper.shared.delete(service: "com.minstagram.auth", account: "userToken")
    }
    
    func isLoggedIn() -> Bool {
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            if JWT.shared.isTokenExpired(token) {
                logOut()
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    
    func isNewUser() -> Bool {
        return UserDefaults.standard.object(forKey: "newUser") != nil
    }

}
