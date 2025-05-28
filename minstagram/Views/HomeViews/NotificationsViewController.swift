//
//  NotificationsViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 21.04.2025.
//

import UIKit

class NotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var notifications: [AppNotification] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTitle()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        NotificationService.shared.fetchNotifications { [weak self] result in
            switch result {
            case .success(let notifications):
                DispatchQueue.main.async {
                    self?.notifications = notifications
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
        
    }
    
    private func setupTitle() {
        let titleLabel = UILabel()
        titleLabel.text = "Notifications"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        navigationItem.titleView = titleLabel
    }
    
    private func goToNotificationsPost(userId: String, notification: AppNotification) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FeedViewController") as! FeedViewController
        vc.mode = .fromNotifications(notification, userId)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backToFeed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell") as? NotificationCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let notification = notifications[indexPath.row]
        if !notification.seen {
            NotificationService.shared.markAsSeen(notificationId: notification.id) { result in
                switch result {
                case .success(let success):
                    self.notifications[indexPath.row].seen = true
                    print(success)
                case .failure(let error):
                    print(error)
                }
            }
        }
        cell.notification = notification
        cell.configure(with: notification)
        cell.onGoProfileTapped = {
            UserService.shared.getProfile(username: notification.sender.username, type: "public", model: UserDetail.self) { result in
                switch result {
                case .success(let detailedUser):
                    DispatchQueue.main.async {
                        let sb = UIStoryboard(name: "Profile", bundle: nil)
                        let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                        vc.user = detailedUser
                        vc.backBtn.isHidden = false
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        cell.onCellTapped = {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.tableView(tableView, didSelectRowAt: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        let type = notification.type
        switch type {
        case .follow:
            let cell = tableView.cellForRow(at: indexPath) as! NotificationCell
            cell.onGoProfileTapped?()
        case .tag:
            let userId = notification.sender.id
            goToNotificationsPost(userId: userId, notification: notification)
        default: ///like or comment
            if let userId = UserManager.shared.activeUser?.id {
                goToNotificationsPost(userId: userId, notification: notification)
            }
        }
    }
    
}
