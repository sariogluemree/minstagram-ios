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
        
        Task { [weak self] in
            do {
                let notifications = try await NetworkManager.shared.request(NotificationEndpoint.list, as: [AppNotification].self)
                self?.notifications = notifications
                self?.tableView.reloadData()
            } catch {
                self?.showError(error)
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
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FeedViewController") as? FeedViewController else { return }
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
            markAsSeen(notificationId: notification.id)
        }
        cell.notification = notification
        cell.configure(with: notification)
        cell.onGoProfileTapped = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                do {
                    let detailedUser = try await NetworkManager.shared.request(UserEndpoint.profile(username: notification.sender.username), as: UserDetail.self)
                    let sb = UIStoryboard(name: "Profile", bundle: nil)
                    guard let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController else { return }
                    vc.user = detailedUser
                    vc.loadViewIfNeeded()
                    vc.backBtn.isHidden = false
                    self?.navigationController?.pushViewController(vc, animated: true)
                } catch {
                    self?.showError(error)
                }
            }
        }
        cell.onCellTapped = { [weak self, weak tableView] in
            guard let self = self, let tableView = tableView,
                  let rowIndex = self.notifications.firstIndex(where: { $0.id == notification.id }) else { return }
            let currentIndexPath = IndexPath(row: rowIndex, section: 0)
            tableView.selectRow(at: currentIndexPath, animated: true, scrollPosition: .none)
            self.tableView(tableView, didSelectRowAt: currentIndexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard notifications.indices.contains(indexPath.row) else { return }
        let notification = notifications[indexPath.row]
        let type = notification.type
        switch type {
        case .follow:
            if let cell = tableView.cellForRow(at: indexPath) as? NotificationCell {
                cell.onGoProfileTapped?()
            }
        case .tag:
            let userId = notification.sender.id
            goToNotificationsPost(userId: userId, notification: notification)
        default: ///like or comment
            if let userId = UserManager.shared.activeUser?.id {
                goToNotificationsPost(userId: userId, notification: notification)
            }
        }
    }
    
    /// Sessiz işlem: başarısız olursa bildirim bir sonraki açılışta tekrar işaretlenir.
    private func markAsSeen(notificationId: String) {
        Task { [weak self] in
            guard let response = try? await NetworkManager.shared.request(NotificationEndpoint.markSeen(id: notificationId), as: MarkSeenResponse.self),
                  response.success,
                  let self = self,
                  let index = self.notifications.firstIndex(where: { $0.id == notificationId }) else { return }
            self.notifications[index].seen = true
        }
    }
    
}
