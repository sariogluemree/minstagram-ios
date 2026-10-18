//
//  ProfileViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 21.04.2025.
//

import UIKit
import SDWebImage

protocol ProfileViewControllerDelegate: AnyObject {
    func didUpdateUserProfile(_ user: UserDetail)
}

class ProfileViewController: UIViewController, ProfileViewControllerDelegate, FollowListViewControllerDelegate {
    
    func didUpdateUserProfile(_ user: UserDetail) {
        self.user = user
        navigationItem.leftBarButtonItems?.removeLast(1)
        setupNavigationTitle(username: user.username)
        nameLbl.text = user.name
        profileImgView.layer.cornerRadius = 50
        profileImgView.clipsToBounds = true
        profileImgView.tintColor = .systemGray
        if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
            profileImgView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            profileImgView.image = UIImage(systemName: "person.crop.circle.fill")
        }
        bioLabel.text = user.bio
    }
    
    func didUpdateFollowCounts(followersCount: Int, followingCount: Int) {
        user?.followersCount = followersCount
        user?.followingCount = followingCount
        followersCountLbl.text = followersCount.description
        followingCountLbl.text = followingCount.description
    }
    
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var postCountLbl: UILabel!
    @IBOutlet weak var followersCountLbl: UILabel!
    @IBOutlet weak var followingCountLbl: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var actionContainerView: UIView!
    @IBOutlet weak var backBtn: UIBarButtonItem!
    
    private var currentActionView: ProfileActionView?
    var collectionView: UICollectionView?
    var user: UserDetail?
    var posts: [Post] = []
    private var isFollowingUser = false
    
    private var isOwnProfile: Bool {
        guard let userId = user?.id else { return false }
        return userId == UserManager.shared.activeUser?.id
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let user = user else { return }
        setupNavigationTitle(username: user.username)
        setupNavigationMenu()
        setupUserProfile(user: user)
        setupStatTapGestures()
        actionContainerView.backgroundColor = .systemBackground
        setupInitialState(userId: user.id)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshProfileCountsAndPosts()
    }
    
    private func setupInitialState(userId: String) {
        if isOwnProfile { // active user state
            self.updateActionView(OwnProfileActionView())
            self.setupCollectionView()
            self.fetchPosts(userId: userId)
        } else {
            Task { [weak self] in
                do {
                    let response = try await NetworkManager.shared.request(FollowEndpoint.isFollowing(userId: userId), as: IsFollowingResponse.self)
                    guard let self = self else { return }
                    self.isFollowingUser = response.isFollowing
                    if response.isFollowing { // followed state
                        self.updateActionView(FollowedProfileActionView())
                        self.setupCollectionView()
                        self.fetchPosts(userId: userId)
                    } else { // unfollowed state
                        self.updateActionView(UnfollowedProfileActionView())
                    }
                } catch {
                    self?.showError(error)
                }
            }
        }
    }
    
    private func refreshProfileCountsAndPosts() {
        guard let currentUsername = user?.username else { return }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard let freshUser = try? await NetworkManager.shared.request(
                UserEndpoint.profile(username: currentUsername),
                as: UserDetail.self
            ) else { return }
            self.user = freshUser
            self.postCountLbl.text = freshUser.postsCount.description
            self.followersCountLbl.text = freshUser.followersCount.description
            self.followingCountLbl.text = freshUser.followingCount.description
            self.nameLbl.text = freshUser.name
            self.bioLabel.text = freshUser.bio
            if self.isOwnProfile {
                UserManager.shared.updateActiveUser(user: freshUser)
                self.fetchPosts(userId: freshUser.id)
            } else if self.isFollowingUser {
                self.fetchPosts(userId: freshUser.id)
            }
        }
    }
    
    func setupNavigationTitle(username: String) {
        let titleLabel = UILabel()
        titleLabel.text = username
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        titleLabel.sizeToFit()
        let titleItem = UIBarButtonItem(customView: titleLabel)
        navigationItem.leftBarButtonItems?.append(titleItem)
    }
    
    private func setupNavigationMenu() {
        if isOwnProfile {
            if let menuBtn = navigationItem.rightBarButtonItem {
                menuBtn.target = self
                menuBtn.action = #selector(didTapMenuButton)
                menuBtn.tintColor = .label
            } else {
                let menuBtn = UIBarButtonItem(
                    image: UIImage(systemName: "line.3.horizontal"),
                    style: .plain,
                    target: self,
                    action: #selector(didTapMenuButton)
                )
                menuBtn.tintColor = .label
                navigationItem.rightBarButtonItem = menuBtn
            }
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func setupStatTapGestures() {
        let followersTargetView = followersCountLbl.superview ?? followersCountLbl!
        followersTargetView.isUserInteractionEnabled = true
        let followersTap = UITapGestureRecognizer(target: self, action: #selector(didTapFollowersStat))
        followersTargetView.addGestureRecognizer(followersTap)
        
        let followingTargetView = followingCountLbl.superview ?? followingCountLbl!
        followingTargetView.isUserInteractionEnabled = true
        let followingTap = UITapGestureRecognizer(target: self, action: #selector(didTapFollowingStat))
        followingTargetView.addGestureRecognizer(followingTap)
        
        let postsTargetView = postCountLbl.superview ?? postCountLbl!
        postsTargetView.isUserInteractionEnabled = true
        let postsTap = UITapGestureRecognizer(target: self, action: #selector(didTapPostsStat))
        postsTargetView.addGestureRecognizer(postsTap)
    }
    
    @objc private func didTapFollowersStat() {
        openFollowList(mode: .followers)
    }
    
    @objc private func didTapFollowingStat() {
        openFollowList(mode: .following)
    }
    
    @objc private func didTapPostsStat() {
        guard !posts.isEmpty, let cv = collectionView, cv.numberOfItems(inSection: 0) > 0 else { return }
        cv.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
    }
    
    private func openFollowList(mode: FollowListMode) {
        guard let user = user else { return }
        let listVC = FollowListViewController(user: user, initialMode: mode)
        listVC.delegate = self
        navigationController?.pushViewController(listVC, animated: true)
    }
    
    @objc private func didTapMenuButton() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Saved", style: .default) { [weak self] _ in
            let savedVC = SavedPostsViewController()
            self?.navigationController?.pushViewController(savedVC, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Edit Profile", style: .default) { [weak self] _ in
            self?.didTapEditProfile()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Share Profile", style: .default) { [weak self] _ in
            self?.didTapShareProfile()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.confirmLogOut()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.confirmDeleteAccount()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(actionSheet, animated: true)
    }
    
    private func confirmLogOut() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out of your account?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            self?.performLogOut()
        })
        present(alert, animated: true)
    }
    
    private func performLogOut() {
        UserManager.shared.logOut()
        transitionToAuthScreen()
    }
    
    private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This action is permanent. All your posts, comments, likes, and profile data will be deleted.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeleteAccount()
        })
        present(alert, animated: true)
    }
    
    private func performDeleteAccount() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                _ = try await NetworkManager.shared.request(UserEndpoint.delete, as: MessageResponse.self)
                UserManager.shared.logOut()
                self.transitionToAuthScreen()
            } catch {
                self.showError(error)
            }
        }
    }
    
    private func transitionToAuthScreen() {
        let authStoryboard = UIStoryboard(name: "Auth", bundle: nil)
        guard let loginVC = authStoryboard.instantiateInitialViewController(),
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.rootViewController = loginVC
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil
        )
    }
    
    func setupUserProfile(user: UserDetail) {
        nameLbl.text = user.name
        profileImgView.layer.cornerRadius = 50
        profileImgView.clipsToBounds = true
        profileImgView.tintColor = .systemGray
        if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
            profileImgView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            profileImgView.image = UIImage(systemName: "person.crop.circle.fill")
        }
        postCountLbl.text = user.postsCount.description
        followersCountLbl.text = user.followersCount.description
        followingCountLbl.text = user.followingCount.description
        bioLabel.numberOfLines = 0
        bioLabel.lineBreakMode = .byWordWrapping
        bioLabel.text = user.bio
    }
    
    private func updateActionView(_ view: ProfileActionView) {

        currentActionView?.removeFromSuperview()

        view.delegate = self
        actionContainerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: actionContainerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: actionContainerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: actionContainerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: actionContainerView.bottomAnchor)
        ])
        
        currentActionView = view
    }
    
    func setupCollectionView() {
        guard collectionView == nil else { return }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(PostCollectionCell.self, forCellWithReuseIdentifier: "PostCollectionCell")
        
        view.addSubview(cv)
        
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: actionContainerView.bottomAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        collectionView = cv
    }
    
    func fetchPosts(userId: String) {
        Task { [weak self] in
            do {
                let posts = try await NetworkManager.shared.request(PostEndpoint.forUser(userId: userId), as: [Post].self)
                self?.posts = posts
                self?.collectionView?.reloadData()
            } catch {
                self?.showError(error)
            }
        }
    }
    
    @IBAction func backBtn(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = 3
        let padding: CGFloat = 4
        let totalSpacing = (itemsPerRow - 1) * padding // spacing + section insets
        let availableWidth = collectionView.bounds.width - totalSpacing
        let width = availableWidth / itemsPerRow
        return CGSize(width: width, height: width)
    }
}

extension ProfileViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCollectionCell", for: indexPath) as? PostCollectionCell else {
            return UICollectionViewCell()
        }
        let post = posts[indexPath.item]
        cell.configure(with: post.imageUrl)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let postIndex = indexPath.row
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FeedViewController") as? FeedViewController else { return }
        vc.mode = .userPosts
        vc.postIndex = postIndex
        vc.posts = posts
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ProfileViewController: ProfileActionViewDelegate {
    
    func didTapEditProfile() {
        let sb = UIStoryboard(name: "Profile", bundle: nil)
        guard let editVC = sb.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController else { return }
        editVC.user = user
        editVC.delegate = self
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    func didTapShareProfile() {
        let sb = UIStoryboard(name: "Profile", bundle: nil)
        guard let shareVC = sb.instantiateViewController(withIdentifier: "ShareProfileViewController") as? ShareProfileViewController else { return }
        shareVC.user = user
        navigationController?.pushViewController(shareVC, animated: true)
    }
    
    func didTapShowRecommendations() {
        let searchVC = UserSearchViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    func didTapUnfollow() {
        guard let user = user else {return}
        Task { [weak self] in
            do {
                try await NetworkManager.shared.request(FollowEndpoint.unfollow(userId: user.id))
                guard let self = self else { return }
                self.isFollowingUser = false
                self.updateActionView(UnfollowedProfileActionView())
                self.posts = []
                self.collectionView?.reloadData()
                if let currentCount = self.user?.followersCount {
                    let updatedCount = max(0, currentCount - 1)
                    self.user?.followersCount = updatedCount
                    self.followersCountLbl.text = updatedCount.description
                }
            } catch {
                self?.showError(error)
            }
        }
    }
    
    func didTapMessage() {
        //Direct Message sayfasına yönlendir.
    }
    
    func didTapFollow() {
        guard let user = user else {return}
        Task { [weak self] in
            do {
                try await NetworkManager.shared.request(FollowEndpoint.follow(userId: user.id))
                guard let self = self else { return }
                self.isFollowingUser = true
                self.updateActionView(FollowedProfileActionView())
                self.setupCollectionView()
                self.fetchPosts(userId: user.id)
                if let currentCount = self.user?.followersCount {
                    let updatedCount = currentCount + 1
                    self.user?.followersCount = updatedCount
                    self.followersCountLbl.text = updatedCount.description
                }
            } catch {
                self?.showError(error)
            }
        }
    }
    
}
