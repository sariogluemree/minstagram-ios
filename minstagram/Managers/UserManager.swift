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
    private init() {
        activeUser = loadCachedUser()
    }

    private enum Keys {
        static let activeUser = "activeUser"
        static let newUser = "newUser"
    }

    @discardableResult
    func loadCachedUser() -> UserDetail? {
        guard let userData = UserDefaults.standard.data(forKey: Keys.activeUser),
              let cachedUser = try? JSONDecoder().decode(UserDetail.self, from: userData) else {
            return nil
        }
        activeUser = cachedUser
        return cachedUser
    }

    /// Cache'teki kullanıcının güncel profilini backend'den çeker.
    /// - Returns: Profil alınabildiyse `true`.
    @MainActor
    func restoreSession() async -> Bool {
        guard let cachedUser = activeUser ?? loadCachedUser() else {
            return false
        }
        do {
            let freshUser = try await NetworkManager.shared.request(
                UserEndpoint.profile(username: cachedUser.username),
                as: UserDetail.self
            )
            updateActiveUser(user: freshUser)
            return true
        } catch let networkError as NetworkError {
            if case .unauthorized = networkError {
                return false
            }
            if case .server(let statusCode, _) = networkError, statusCode == 404 {
                return false
            }
            // Geçici bağlantı hatalarında cache'teki kullanıcı ile devam et
            return true
        } catch {
            return true
        }
    }

    func updateActiveUser(user: UserDetail) {
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: Keys.activeUser)
        }
        activeUser = user
    }


    func getNewRegisteredUserName() -> String? {
        guard let userData = UserDefaults.standard.data(forKey: Keys.newUser) else {
            return nil
        }
        return (try? JSONDecoder().decode(UserDetail.self, from: userData))?.username
    }

    /// Kayıt sonrası login ekranında kullanıcı adını önceden doldurmak için saklanır.
    func register(user: UserDetail) {
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: Keys.newUser)
        }
    }

    func login(token: String, user: UserDetail) {
        KeychainHelper.shared.save(Data(token.utf8), service: AuthKeychain.service, account: AuthKeychain.account)
        updateActiveUser(user: user)
    }

    func logOut() {
        activeUser = nil
        UserDefaults.standard.removeObject(forKey: Keys.newUser)
        UserDefaults.standard.removeObject(forKey: Keys.activeUser)
        KeychainHelper.shared.delete(service: AuthKeychain.service, account: AuthKeychain.account)
    }

    func isLoggedIn() -> Bool {
        guard let token = KeychainTokenProvider().token else {
            return false
        }
        if JWT.shared.isTokenExpired(token) {
            logOut()
            return false
        }
        return true
    }

    func isNewUser() -> Bool {
        return UserDefaults.standard.object(forKey: Keys.newUser) != nil
    }

}
