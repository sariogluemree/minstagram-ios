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
        if !user.profilePhoto.isEmpty {
            let ppUrl = user.profilePhoto
            let url = URL(string: ppUrl)
            profileImgView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
            profileImgView.layer.cornerRadius = 50
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
    var collectionView: UICollectionView!
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
            FollowService.shared.isFollowing(followingId: userId) { isFollowing, error in
                if let error = error {
                    print("Hata: \(error.localizedDescription)")
                } else if let isFollowing = isFollowing {
                    if isFollowing { //followed state
                        DispatchQueue.main.async {
                            self.updateActionView(FollowedProfileActionView())
                            self.setupCollectionView()
                            self.fetchPosts(userId: userId)
                        }
                    } else { //unfollowed state
                        DispatchQueue.main.async {
                            self.updateActionView(UnfollowedProfileActionView())
                        }
                    }
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
        if !user.profilePhoto.isEmpty {
            let ppUrl = user.profilePhoto
            let url = URL(string: ppUrl)
            profileImgView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
            profileImgView.layer.cornerRadius = 50
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
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PostCollectionCell.self, forCellWithReuseIdentifier: "PostCollectionCell")
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: actionContainerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func fetchPosts(userId: String) {
        PostService.shared.fetchPosts(byUserId: userId) { result in
            switch result {
            case .success(let posts):
                self.posts = posts
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            case .failure(let error):
                print("Error fetching posts: \(error)")
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
}

extension ProfileViewController: ProfileActionViewDelegate {
    
    func didTapEditProfile() {
        let sb = UIStoryboard(name: "Profile", bundle: nil)
        let editVC = sb.instantiateViewController(withIdentifier: "EditProfileViewController") as! EditProfileViewController
        editVC.user = user
        editVC.delegate = self
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    func didTapShareProfile() {
        let sb = UIStoryboard(name: "Profile", bundle: nil)
        let shareVC = sb.instantiateViewController(withIdentifier: "ShareProfileViewController") as! ShareProfileViewController
        navigationController?.pushViewController(shareVC, animated: true)
    }
    
    func didTapShowRecommendations() {
        let sb = UIStoryboard(name: "Profile", bundle: nil)
        let searchVC = sb.instantiateViewController(withIdentifier: "UserSearchViewController") as! UserSearchViewController
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    func didTapUnfollow() {
        guard let user = user else {return}
        FollowService.shared.unfollowUser(followingId: user.id) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.updateActionView(UnfollowedProfileActionView())
                    self?.posts = []
                    self?.collectionView.reloadData()
                }
            } else {
                print("error: \(error ?? "Başarısız işlem")")
            }
        }
    }
    
    func didTapMessage() {
        //Direct Message sayfasına yönlendir.
    }
    
    func didTapFollow() {
        guard let user = user else {return}
        FollowService.shared.followUser(followingId: user.id) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.updateActionView(FollowedProfileActionView())
                    self?.setupCollectionView()
                    self?.fetchPosts(userId: user.id)
                }
            } else {
                print("error: \(error ?? "Başarısız işlem")")
            }
        }
    }
    
}
