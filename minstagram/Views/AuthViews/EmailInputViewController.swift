//
//  EmailInputViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 1.03.2025.
//

import UIKit

class EmailInputViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        }
    
    @IBAction func nextPressed(_ sender: UIButton) {
        guard let email = emailField.text, Validator.isValidEmail(email) else {
            showAlert(message: "Lütfen geçerli bir e-posta adresi giriniz.")
            return
        }
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "VerifyEmailViewController") as? VerifyEmailViewController {
            vc.userEmail = email
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func backPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backToLogin(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
