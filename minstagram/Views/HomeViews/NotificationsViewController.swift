//
//  NotificationsViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 21.04.2025.
//

import UIKit

class NotificationsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleLabel = UILabel()
        titleLabel.text = "Notifications"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        navigationItem.titleView = titleLabel
    }
    @IBAction func backToFeed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
}
