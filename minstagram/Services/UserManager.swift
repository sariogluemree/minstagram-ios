//
//  UserManager.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 8.03.2025.
//

import Foundation

class UserManager {
    static let shared = UserManager()
    var activeUser: UserDetail?
    private init() {}
    
    func getActiveUser() {
        if let userData = UserDefaults.standard.data(forKey: "activeUser") {
            do {
                let loggedInUser = try JSONDecoder().decode(UserDetail.self, from: userData)
                print("loggedInUser: \(loggedInUser)")
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
            let registeredUser = try JSONDecoder().decode(UserDetail.self, from: userData)
            return registeredUser.username
        } catch {
            print("Decoding error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func register(user: UserDetail) {
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: "newUser")
        }
    }
    
    func login(tokenData: Data, user: UserDetail) {
        KeychainHelper.shared.save(tokenData, service: "com.minstagram.auth", account: "userToken")
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: "activeUser")
        }
        activeUser = user
        print("active user: \(activeUser?.username ?? "user")")
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
                print("token: \(token) expired")
                logOut()
                return false
            } else {
                print("token: \(token)")
                return true
            }
        } else {
            print("token couldn't be found")
            return false
        }
    }
    
    func isNewUser() -> Bool {
        return UserDefaults.standard.object(forKey: "newUser") != nil
    }

}
