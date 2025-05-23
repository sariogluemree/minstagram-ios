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
    
    var mode: FeedViewControllerMode = .feed
    var posts: [Post] = []
    var postIndex: Int?
    private var refreshControl: UIRefreshControl?
    
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
        PostService.shared.fetchAllPosts { [weak self] result in
            guard let self = self else { return }
            switch(result) {
            case .success(let posts):
                self.posts = posts
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching posts: \(error)")
            }
        }
    }
    
    private func fetchUserPosts(userId: String) {
        PostService.shared.fetchPosts(byUserId: userId){ [weak self] result in
            guard let self = self else { return }
            switch(result) {
            case .success(let posts):
                self.posts = posts
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToInitialPostIfNeeded()
                }
            case .failure(let error):
                print("Error fetching posts: \(error)")
            }
        }
    }
    
    @objc private func refreshFeed() {
        PostService.shared.fetchAllPosts { [weak self] result in
            DispatchQueue.main.async {
                switch(result) {
                case .success(let posts):
                    self?.posts = posts
                    self?.tableView.reloadData()
                case .failure(let error):
                    print(error)
                    //alert örneği
                    /*let alert = UIAlertController(
                        title: "Hata",
                        message: "Gönderiler yüklenirken bir hata oluştu: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                    self?.present(alert, animated: true)*/
                }
                self?.refreshControl?.endRefreshing()
            }
        }
    }
    
    func refreshPost(withId id: String, at indexPath: IndexPath) {
        PostService.shared.fetchPost(byId: id) { [weak self] result in
            switch result {
            case .success(let updatedPost):
                DispatchQueue.main.async {
                    self?.posts[indexPath.row] = updatedPost
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    @IBAction func showNotifications(_ sender: UIBarButtonItem) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
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
                PostService.shared.deletePost(byId: post.id) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let message):
                            self.posts.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with    : .automatic)
                            print(message)
                        case .failure(let error):
                            print(error)
                        }
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
        
        cell.onLikeTapped = {
            if post.isLiked {
                LikeService.shared.unlikePost(postId: post.id) { result in
                    switch result {
                    case .success(let message):
                        print(message)
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            } else {
                LikeService.shared.likePost(postId: post.id) { result in
                    switch result {
                    case .success(_):
                        print("Post liked")
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        cell.onSaveTapped = {
            if post.isSaved {
                SavedPostService.shared.unsavePost(postId: post.id) { result in
                    switch result {
                    case .success(let message):
                        print(message)
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            } else {
                SavedPostService.shared.savePost(postId: post.id) { result in
                    switch result {
                    case .success(_):
                        print("Post saved")
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        
        cell.onGoProfileTapped = {
            UserService.shared.getProfile(username: post.user.username, type: "public", model: UserDetail.self) { result in
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


