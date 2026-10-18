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

class ProfileViewController: UIViewController, ProfileViewControllerDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let user = user else { return }
        setupNavigationTitle(username: user.username)
        setupUserProfile(user: user)
        actionContainerView.backgroundColor = .systemBackground
        setupInitialState(userId: user.id)
    }
    
    private func setupInitialState(userId: String) {
        if userId == UserManager.shared.activeUser?.id { //active user state
            self.updateActionView(OwnProfileActionView())
            self.setupCollectionView()
            self.fetchPosts(userId: userId)
        } else {
            Task { [weak self] in
                do {
                    let response = try await NetworkManager.shared.request(FollowEndpoint.isFollowing(userId: userId), as: IsFollowingResponse.self)
                    guard let self = self else { return }
                    if response.isFollowing { //followed state
                        self.updateActionView(FollowedProfileActionView())
                        self.setupCollectionView()
                        self.fetchPosts(userId: userId)
                    } else { //unfollowed state
                        self.updateActionView(UnfollowedProfileActionView())
                    }
                } catch {
                    self?.showError(error)
                }
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
