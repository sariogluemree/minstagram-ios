//
//  CreateAccountViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 1.03.2025.
//

import UIKit

class CreateAccountViewController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var newUserEmail: String?
    let authService = AuthService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func createNewAccount(_ sender: UIButton) {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let email = newUserEmail else {
            showAlert(message: "Kullanıcı adı ve şifre boş olamaz.")
            return
        }
        
        authService.register(email: email, username: username, password: password) { [weak self] success, message in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    self.showAlert(message: message ?? "Kayıt başarısız.")
                }
            }
        }
    }
    
    @IBAction func backPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
}
