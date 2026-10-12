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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserManager.shared.isNewUser() {
            self.userField.text = UserManager.shared.getNewRegisteredUserName()
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
        
        Task { [weak self] in
            do {
                let request = LoginRequest(emailOrUsername: emailOrUsername, password: password)
                let response = try await NetworkManager.shared.request(AuthEndpoint.login(request), as: LoginResponse.self)
                UserManager.shared.login(token: response.token, user: response.user)
                self?.view.window?.rootViewController = MainTabBarController()
            } catch {
                self?.showError(error)
            }
        }
    }
    
    @IBAction func createAccPressed(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "EmailInputViewController") as? EmailInputViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
