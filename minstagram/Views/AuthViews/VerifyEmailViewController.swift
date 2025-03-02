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
    let emailService = EmailService()
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        if let email = userEmail {
            sendCode(to: email)
        }
    }
    
    func sendCode(to email: String) {
        emailService.sendVerificationCode(to: email) { [weak self] success, message in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.showAlert(title: "Başarılı", message: message ?? "Email doğrulama kodu gönderildi!")
                } else {
                    self.showAlert(title: "Hata!", message: message ?? "Email gönderme işlemi başarısız.")
                }
            }
        }
    }
    
    @IBAction func nextPressed(_ sender: UIButton) {
        guard let code = codeField.text, emailService.isValidCode(code) else {
            showAlert(title: "Hata!", message: "Geçerli bir kod giriniz")
            return
        }
        if let email = userEmail {
            emailService.verifyEmail(email: email, code: code) { [weak self] success, message in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if success {
                        let sb = UIStoryboard(name: "Auth", bundle: nil)
                        if let vc = sb.instantiateViewController(withIdentifier: "CreateAccountViewController") as? CreateAccountViewController {
                            vc.newUserEmail = email
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    } else {
                        self.showAlert(title: "Hata", message: message ?? "Email doğrulanamadı.")
                    }
                }
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
}
