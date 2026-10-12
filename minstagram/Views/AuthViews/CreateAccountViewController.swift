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
        
        Task { [weak self] in
            do {
                let request = RegisterRequest(email: email, username: username, password: password)
                let response = try await NetworkManager.shared.request(AuthEndpoint.register(request), as: RegisterResponse.self)
                UserManager.shared.register(user: response.newUser)
                self?.navigationController?.popToRootViewController(animated: true)
            } catch {
                self?.showError(error)
            }
        }
    }
    
    @IBAction func backPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
