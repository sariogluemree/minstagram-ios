//
//  Validator.swift
//  minstagram
//

import Foundation

enum Validator {

    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// 6 haneli sayısal doğrulama kodu.
    static func isValidCode(_ code: String) -> Bool {
        return code.count == 6 && code.allSatisfy { $0.isNumber }
    }
}
