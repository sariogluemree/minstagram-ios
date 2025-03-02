//
//  LoginViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 1.03.2025.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    let authService = AuthService()
    var newUser: User?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let user = newUser {
            self.userField.text = user.username
        }
    }
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        guard let emailOrUsername = userField.text, !emailOrUsername.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(message: "Kullanıcı adı ve şifre boş olamaz.")
            return
        }
        
        authService.login(user: emailOrUsername, password: password) { [weak self] success, loggedInUser, errorMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    let sb = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = sb.instantiateViewController(withIdentifier: "FeedViewController") as? FeedViewController {
                        vc.user = loggedInUser
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    self.showAlert(message: errorMessage ?? "Giriş başarısız.")
                }
            }
        }
    }
    
    @IBAction func createAccPressed(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "EmailInputViewController") as? EmailInputViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
}
