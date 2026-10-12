//
//  UIViewController+Alert.swift
//  minstagram
//

import UIKit

extension UIViewController {

    func showAlert(title: String = "Hata", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }

    /// Hata mesajını tek tip alert ile gösterir.
    /// Oturum sona erdiğinde (401) alert gösterilmez; SceneDelegate kullanıcıyı login ekranına yönlendirir.
    func showError(_ error: Error, title: String = "Hata") {
        if let networkError = error as? NetworkError, networkError.isUnauthorized || networkError.isCancelled {
            return
        }
        if error is CancellationError { return }
        showAlert(title: title, message: error.localizedDescription)
    }
}
