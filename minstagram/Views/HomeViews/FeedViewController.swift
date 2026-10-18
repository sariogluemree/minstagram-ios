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
    private var expandedPostIds: Set<String> = []
    private var hiddenLikeCountPostIds: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch mode {
        case .feed:
            setupNavigationBarForFeed()
            setupTableView()
            fetchAllPosts()
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
        backButtonItem.tintColor = .label
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
        guard self.tableView.numberOfRows(inSection: 0) > 0, !posts.isEmpty else { return }

        switch mode {
        case .userPosts:
            if let postIndex = self.postIndex, posts.indices.contains(postIndex) {
                let indexPath = IndexPath(row: postIndex, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        case .fromNotifications(let notification, _):
            let index = posts.firstIndex(where: { $0.id == notification.postId }) ?? 0
            guard posts.indices.contains(index) else { return }
            self.postIndex = index
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, self.posts.indices.contains(index) else { return }
                switch notification.type {
                case .tag:
                    if let cell = self.tableView.cellForRow(at: indexPath) as? PostCell {
                        cell.toggleTagHidden(cell.taggedPeopleIcon)
                    }
                case .comment:
                    let comments = self.posts[index].comments
                    let commentIndex = comments.firstIndex(where: { $0.id == notification.comment?.id })
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
    
    func refreshPost(withId id: String, at indexPath: IndexPath? = nil) {
        Task { [weak self] in
            // Sessiz yenileme: hata olursa mevcut hücre olduğu gibi kalır.
            guard let updatedPost = try? await NetworkManager.shared.request(PostEndpoint.detail(id: id), as: Post.self),
                  let self = self,
                  let rowIndex = self.posts.firstIndex(where: { $0.id == id }) else { return }
            self.posts[rowIndex] = updatedPost
            let targetIndexPath = IndexPath(row: rowIndex, section: 0)
            self.tableView.reloadRows(at: [targetIndexPath], with: .none)
        }
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func showNotifications(_ sender: UIBarButtonItem) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "NotificationsViewController") as? NotificationsViewController else { return }
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
        notificationsBtn?.image = UIImage(systemName: "suit.heart.fill")
        notificationsBtn?.tintColor = .systemRed
    }
    
    private func removeRedDotFromBarButton() {
        notificationsBtn?.image = UIImage(systemName: "suit.heart")
        notificationsBtn?.tintColor = .label
    }
    
    private func startNotificationCheckTimer() {
        notificationCheckTimer?.invalidate()
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
        let isExpanded = expandedPostIds.contains(post.id)
        let isLikeCountHidden = hiddenLikeCountPostIds.contains(post.id)
        
        cell.post = post
        cell.isExpandedCaption = isExpanded
        cell.configure(with: post, isTruncated: !isExpanded)
        if isLikeCountHidden {
            cell.likeCountLabel.text = "*** likes"
        }
        
        cell.onOptionsTapped = { [weak self, weak cell] in
            guard let self = self else { return }
            let actionSheet = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Edit post", style: .default, handler: { _ in
                //edit sayfası yap.
            }))
            actionSheet.addAction(UIAlertAction(title: "Delete post", style: .destructive, handler: { [weak self] _ in
                Task { @MainActor [weak self] in
                    do {
                        try await NetworkManager.shared.request(PostEndpoint.delete(id: post.id))
                        guard let self = self, let index = self.posts.firstIndex(where: { $0.id == post.id }) else { return }
                        self.expandedPostIds.remove(post.id)
                        self.hiddenLikeCountPostIds.remove(post.id)
                        self.posts.remove(at: index)
                        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    } catch {
                        self?.showError(error)
                    }
                }
            }))
            ///like count tek option şeklinde olacak. post'un likeCount'u için flag tutulacak. bu option bool değer için toggle yapacak ve ona göre ui düzenleyecek.
            actionSheet.addAction(UIAlertAction(title: "Hide like count", style: .default, handler: { [weak self, weak cell] _ in
                self?.hiddenLikeCountPostIds.insert(post.id)
                cell?.likeCountLabel.text = "*** likes"
            }))
            actionSheet.addAction(UIAlertAction(title: "Show like count", style: .default, handler: { [weak self, weak cell] _ in
                self?.hiddenLikeCountPostIds.remove(post.id)
                let currentCount = self?.posts.first(where: { $0.id == post.id })?.likeCount ?? post.likeCount
                cell?.likeCountLabel.text = "\(currentCount) likes"
            }))

            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            // Present it (e.g., in a view controller)
            self.present(actionSheet, animated: true, completion: nil)
        }
        
        cell.onLikeTapped = { [weak self] in
            guard let self = self else { return }
            let currentPost = self.posts.first(where: { $0.id == post.id }) ?? post
            let endpoint: LikeEndpoint = currentPost.isLiked ? .unlike(postId: post.id) : .like(postId: post.id)
            Task { @MainActor [weak self] in
                do {
                    try await NetworkManager.shared.request(endpoint)
                    self?.refreshPost(withId: post.id)
                } catch {
                    self?.showError(error)
                }
            }
        }
        cell.onSaveTapped = { [weak self] in
            guard let self = self else { return }
            let currentPost = self.posts.first(where: { $0.id == post.id }) ?? post
            let endpoint: SavedPostEndpoint = currentPost.isSaved ? .unsave(postId: post.id) : .save(postId: post.id)
            Task { @MainActor [weak self] in
                do {
                    try await NetworkManager.shared.request(endpoint)
                    self?.refreshPost(withId: post.id)
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
        
        cell.onCaptionTapped = { [weak self, weak cell, weak tableView] in
            guard let self = self, let cell = cell else { return }
            let currentPost = self.posts.first(where: { $0.id == post.id }) ?? post
            let shouldExpand = !self.expandedPostIds.contains(post.id)
            if shouldExpand {
                self.expandedPostIds.insert(post.id)
            } else {
                self.expandedPostIds.remove(post.id)
            }
            cell.configure(with: currentPost, isTruncated: !shouldExpand)
            if self.hiddenLikeCountPostIds.contains(post.id) {
                cell.likeCountLabel.text = "*** likes"
            }
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
        
        cell.onCommentTapped = { [weak self] in
            guard let self = self,
                  let rowIndex = self.posts.firstIndex(where: { $0.id == post.id }) else { return }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let commentsNav = storyboard.instantiateViewController(withIdentifier: "CommentsNavController") as? UINavigationController,
               let commentsVC = commentsNav.viewControllers.first as? CommentsViewController {
                commentsVC.delegate = self
                commentsVC.post = self.posts[rowIndex]
                commentsVC.postIndex = IndexPath(row: rowIndex, section: 0)
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
        guard posts.indices.contains(index.row) else { return }
        let post = posts[index.row]
        self.refreshPost(withId: post.id, at: index)
    }
    

}


