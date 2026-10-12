//
//  TokenProvider.swift
//  minstagram
//

import Foundation

protocol TokenProviding {
    var token: String? { get }
}

/// Auth token'ının Keychain'deki konumu. Token'a erişen her yer bu sabitleri kullanır.
enum AuthKeychain {
    static let service = "com.minstagram.auth"
    static let account = "userToken"
}

/// Token'ı her erişimde Keychain'den okur; böylece login/logout sonrası bayat token kullanılmaz.
struct KeychainTokenProvider: TokenProviding {
    var token: String? {
        guard let data = KeychainHelper.shared.read(service: AuthKeychain.service, account: AuthKeychain.account),
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            return nil
        }
        return token
    }
}
