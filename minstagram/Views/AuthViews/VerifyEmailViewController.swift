//
//  VerifyEmailViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 1.03.2025.
//

import UIKit

class VerifyEmailViewController: UIViewController {
    
    @IBOutlet weak var codeField: UITextField!
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        }
    
    @IBAction func nextPressed(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "CreateAccountViewController") as? CreateAccountViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func resendCode(_ sender: UIButton) {
    }
    
    @IBAction func backPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
}
