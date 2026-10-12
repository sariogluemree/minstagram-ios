//
//  VerifyEmailViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 1.03.2025.
//

import UIKit

class VerifyEmailViewController: UIViewController {
    
    @IBOutlet weak var codeField: UITextField!
    
    var userEmail: String?
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        if let email = userEmail {
            sendCode(to: email)
        }
    }
    
    func sendCode(to email: String) {
        Task { [weak self] in
            do {
                let response = try await NetworkManager.shared.request(VerificationEndpoint.sendCode(email: email), as: MessageResponse.self)
                self?.showAlert(title: "Başarılı", message: response.message)
            } catch {
                self?.showError(error, title: "Hata!")
            }
        }
    }
    
    @IBAction func nextPressed(_ sender: UIButton) {
        guard let code = codeField.text, Validator.isValidCode(code) else {
            showAlert(title: "Hata!", message: "Geçerli bir kod giriniz")
            return
        }
        guard let email = userEmail else { return }
        
        Task { [weak self] in
            do {
                try await NetworkManager.shared.request(VerificationEndpoint.verify(email: email, code: code))
                let sb = UIStoryboard(name: "Auth", bundle: nil)
                if let vc = sb.instantiateViewController(withIdentifier: "CreateAccountViewController") as? CreateAccountViewController {
                    vc.newUserEmail = email
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                self?.showError(error)
            }
        }
    }
    
    @IBAction func resendCode(_ sender: UIButton) { //1dk boyunca tıklanamasın özelliği eklenecek.
        if let email = userEmail {
            sendCode(to: email)
        }
    }
    
    @IBAction func backPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
