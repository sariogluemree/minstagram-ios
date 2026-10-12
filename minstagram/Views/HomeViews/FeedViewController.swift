//
//  ViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 19.02.2025.
//

import UIKit
import SDWebImage

enum FeedViewControllerMode {
    case feed
    case userPosts
    case fromNotifications(AppNotification, String)
}

class FeedViewController: UIViewController, CommentsViewControllerDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var notificationsBtn: UIBarButtonItem!
    
    var mode: FeedViewControllerMode = .feed
    var posts: [Post] = []
    var postIndex: Int?
    private var refreshControl: UIRefreshControl?
    private var notificationCheckTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch mode {
        case .feed:
            setupNavigationBarForFeed()
            setupTableView()
            fetchAllPosts()
            checkUnseenNotificationsAndUpdateUI()
            startNotificationCheckTimer()
        case .userPosts:
            setupNavigationBarForUser()
            setupTableView()
            scrollToInitialPostIfNeeded()
        case .fromNotifications(_, let userId):
            setupNavigationBarForUser()
            setupTableView()
            fetchUserPosts(userId: userId)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if case .feed = mode {
            checkUnseenNotificationsAndUpdateUI()
            startNotificationCheckTimer()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationCheckTimer?.invalidate()
        notificationCheckTimer = nil
    }
    
    private func setupNavigationBarForFeed() {
        let titleLabel = UILabel()
        titleLabel.text = "Minstagram"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        titleLabel.sizeToFit()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }
    
    private func setupNavigationBarForUser() {
        let titleLabel = UILabel()
        titleLabel.text = "Posts"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        titleLabel.sizeToFit()
        let backButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.backward"), style: .plain, target: self, action: #selector(back))
        backButtonItem.tintColor = .black
        navigationItem.leftBarButtonItem = backButtonItem
        let titleItem = UIBarButtonItem(customView: titleLabel)
        navigationItem.leftBarButtonItems?.append(titleItem)
        navigationItem.rightBarButtonItem = nil
    }
    
    private func setupTableView() {
        let nib = UINib(nibName: "PostCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "PostCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 600
        
        switch mode {
        case .feed:
            let rC = UIRefreshControl()
            refreshControl = rC
            self.refreshControl?.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
            tableView.refreshControl = refreshControl
        default:
            break
        }
        
    }
    
    private func scrollToInitialPostIfNeeded() {
        guard self.tableView.numberOfRows(inSection: 0) > 0 else { return }

        switch mode {
        case .userPosts:
            if let postIndex = self.postIndex {
                let indexPath = IndexPath(row: postIndex, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        case .fromNotifications(let notification, _):
            let index = posts.firstIndex(where: { $0.id == notification.postId }) ?? 0
            self.postIndex = index
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                switch notification.type {
                case .tag:
                    if let cell = self.tableView.cellForRow(at: indexPath) as? PostCell {
                        cell.toggleTagHidden(cell.taggedPeopleIcon)
                    }
                case .comment:
                    let comments = self.posts[index].comments
                    let commentIndex = comments.firstIndex(where: { $0.id == notification.comment?.id }) ?? 0
                    if let commentsNav = UIStoryboard(name: "Main", bundle: nil)
                        .instantiateViewController(withIdentifier: "CommentsNavController") as? UINavigationController,
                       let commentsVC = commentsNav.viewControllers.first as? CommentsViewController {
                        commentsVC.delegate = self
                        commentsVC.postIndex = indexPath
                        commentsVC.post = self.posts[index]
                        commentsVC.commentIndex = commentIndex
                        commentsNav.modalPresentationStyle = .pageSheet
                        self.present(commentsNav, animated: true)
                    }
                default:
                    break
                }
            }
        default:
            break
        }
    }
    
    private func fetchAllPosts() {
        Task { [weak self] in
            do {
                let posts = try await NetworkManager.shared.request(PostEndpoint.feed, as: [Post].self)
                self?.posts = posts
                self?.tableView.reloadData()
            } catch {
                self?.showError(error)
            }
        }
    }
    
    private func fetchUserPosts(userId: String) {
        Task { [weak self] in
            do {
                let posts = try await NetworkManager.shared.request(PostEndpoint.forUser(userId: userId), as: [Post].self)
                self?.posts = posts
                self?.tableView.reloadData()
                self?.scrollToInitialPostIfNeeded()
            } catch {
                self?.showError(error)
            }
        }
    }
    
    @objc private func refreshFeed() {
        Task { [weak self] in
            do {
                let posts = try await NetworkManager.shared.request(PostEndpoint.feed, as: [Post].self)
                self?.posts = posts
                self?.tableView.reloadData()
            } catch {
                self?.showError(error)
            }
            self?.refreshControl?.endRefreshing()
        }
    }
    
    func refreshPost(withId id: String, at indexPath: IndexPath) {
        Task { [weak self] in
            // Sessiz yenileme: hata olursa mevcut hücre olduğu gibi kalır.
            guard let updatedPost = try? await NetworkManager.shared.request(PostEndpoint.detail(id: id), as: Post.self),
                  let self = self, self.posts.indices.contains(indexPath.row) else { return }
            self.posts[indexPath.row] = updatedPost
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func showNotifications(_ sender: UIBarButtonItem) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
        navigationController?.pushViewController(vc, animated: true)
        removeRedDotFromBarButton()
    }
    
    func checkUnseenNotificationsAndUpdateUI() {
        Task { [weak self] in
            // Periyodik kontrol: hata kullanıcıya gösterilmez (NetworkLogger DEBUG'da loglar).
            guard let response = try? await NetworkManager.shared.request(NotificationEndpoint.hasUnseen, as: HasUnseenResponse.self) else { return }
            self?.updateNotificationDot(hasUnseen: response.hasUnseen)
        }
    }
    
    func updateNotificationDot(hasUnseen: Bool) {
        if hasUnseen {
            addRedDotToBarButton()
        } else {
            removeRedDotFromBarButton()
        }
    }
    
    private func addRedDotToBarButton() {
        // Önce mevcut kırmızı noktayı kaldır
        removeRedDotFromBarButton()
        
        // Yeni bir view oluştur
        let redDotSize: CGFloat = 10
        let redDot = UIView(frame: CGRect(x: 0, y: 0, width: redDotSize, height: redDotSize))
        redDot.backgroundColor = .systemRed
        redDot.layer.cornerRadius = redDotSize / 2
        redDot.clipsToBounds = true
        redDot.tag = 999
        
        // Kırmızı noktayı tıklanabilir yap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showNotifications(_:)))
        redDot.isUserInteractionEnabled = true
        redDot.addGestureRecognizer(tapGesture)
        
        // Bar button item'ın view'ını bul
        if let buttonView = notificationsBtn.value(forKey: "view") as? UIView {
            buttonView.addSubview(redDot)
            
            // Kırmızı noktayı sağ üst köşeye yerleştir
            redDot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                redDot.bottomAnchor.constraint(equalTo: buttonView.bottomAnchor, constant: -10),
                redDot.trailingAnchor.constraint(equalTo: buttonView.trailingAnchor, constant: -10),
                redDot.widthAnchor.constraint(equalToConstant: redDotSize),
                redDot.heightAnchor.constraint(equalToConstant: redDotSize)
            ])
        }
    }
    
    private func removeRedDotFromBarButton() {
        if let buttonView = notificationsBtn.value(forKey: "view") as? UIView {
            buttonView.viewWithTag(999)?.removeFromSuperview()
        }
    }
    
    private func startNotificationCheckTimer() {
        notificationCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkUnseenNotificationsAndUpdateUI()
        }
    }

}

extension FeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let post = posts[indexPath.row]
        
        cell.post = post
        cell.configure(with: post, isTruncated: cell.isExpandedCaption)
        
        cell.onOptionsTapped = {
            let actionSheet = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Edit post", style: .default, handler: { _ in
                //edit sayfası yap.
            }))
            actionSheet.addAction(UIAlertAction(title: "Delete post", style: .default, handler: { _ in
                Task { @MainActor [weak self] in
                    do {
                        try await NetworkManager.shared.request(PostEndpoint.delete(id: post.id))
                        guard let self = self, let index = self.posts.firstIndex(where: { $0.id == post.id }) else { return }
                        self.posts.remove(at: index)
                        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    } catch {
                        self?.showError(error)
                    }
                }
            }))
            ///like count tek option şeklinde olacak. post'un likeCount'u için flag tutulacak. bu option bool değer için toggle yapacak ve ona göre ui düzenleyecek.
            actionSheet.addAction(UIAlertAction(title: "Hide like count", style: .default, handler: { _ in
                cell.likeCountLabel.text = "*** likes"
            }))
            actionSheet.addAction(UIAlertAction(title: "Show like count", style: .default, handler: { _ in
                cell.likeCountLabel.text = "\(post.likeCount) likes"
            }))

            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            // Present it (e.g., in a view controller)
            self.present(actionSheet, animated: true, completion: nil)
        }
        
        cell.onLikeTapped = { [weak self] in
            guard let self = self else { return }
            let endpoint: LikeEndpoint = post.isLiked ? .unlike(postId: post.id) : .like(postId: post.id)
            Task { @MainActor [weak self] in
                do {
                    try await NetworkManager.shared.request(endpoint)
                    self?.refreshPost(withId: post.id, at: indexPath)
                } catch {
                    self?.showError(error)
                }
            }
        }
        cell.onSaveTapped = { [weak self] in
            guard let self = self else { return }
            let endpoint: SavedPostEndpoint = post.isSaved ? .unsave(postId: post.id) : .save(postId: post.id)
            Task { @MainActor [weak self] in
                do {
                    try await NetworkManager.shared.request(endpoint)
                    self?.refreshPost(withId: post.id, at: indexPath)
                } catch {
                    self?.showError(error)
                }
            }
        }
        
        cell.onGoProfileTapped = { [weak self] in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                do {
                    let detailedUser = try await NetworkManager.shared.request(UserEndpoint.profile(username: post.user.username), as: UserDetail.self)
                    let sb = UIStoryboard(name: "Profile", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    vc.user = detailedUser
                    vc.backBtn.isHidden = false
                    self?.navigationController?.pushViewController(vc, animated: true)
                } catch {
                    self?.showError(error)
                }
            }
        }
        
        cell.onCaptionTapped = {
            cell.configure(with: post, isTruncated: !cell.isExpandedCaption)
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        cell.onCommentTapped = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let commentsNav = storyboard.instantiateViewController(withIdentifier: "CommentsNavController") as? UINavigationController {
                let commentsVC = commentsNav.viewControllers.first as! CommentsViewController
                commentsVC.delegate = self
                commentsVC.post = post
                commentsVC.postIndex = indexPath
                commentsNav.modalPresentationStyle = .pageSheet
                self.present(commentsNav, animated: true, completion: nil)
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? PostCell {
            cell.postImageView.subviews.forEach { $0.isHidden = true }
        }
    }
    
    func commentsViewController(_ controller: CommentsViewController, commentAddedAt index: IndexPath) {
        let post = posts[index.row]
        self.refreshPost(withId: post.id, at: index)
    }
    

}


