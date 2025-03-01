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
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        }
    
    @IBAction func loginPressed(_ sender: UIButton) {
    }
    
    @IBAction func createAccPressed(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Auth", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "EmailInputViewController") as? EmailInputViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
