//
//  PostView.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 16.04.2025.
//

import UIKit

class PostView: UIView {
    
    // MARK: - UI Elements
    
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let postImageView = UIImageView()
    
    private let likeButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)

    private let likeCountLabel = UILabel()
    private let captionLabel = UILabel()
    private let commentsPreviewLabel = UILabel()
    private let addCommentButton = UIButton(type: .system)
    
    //private var tagView: UIView?

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .systemBackground

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        profileImageView.backgroundColor = .lightGray

        usernameLabel.font = UIFont.boldSystemFont(ofSize: 14)

        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
        postImageView.backgroundColor = .secondarySystemBackground

        [likeButton, commentButton, shareButton].forEach {
            $0.tintColor = .label
        }

        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        commentButton.setImage(UIImage(systemName: "bubble.right"), for: .normal)
        shareButton.setImage(UIImage(systemName: "paperplane"), for: .normal)

        likeCountLabel.font = UIFont.boldSystemFont(ofSize: 14)
        captionLabel.font = UIFont.systemFont(ofSize: 14)
        captionLabel.numberOfLines = 0

        commentsPreviewLabel.font = UIFont.systemFont(ofSize: 13)
        commentsPreviewLabel.textColor = .gray
        commentsPreviewLabel.numberOfLines = 2

        addCommentButton.setTitle("Add a comment...", for: .normal)
        addCommentButton.setTitleColor(.gray, for: .normal)
        addCommentButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        addCommentButton.contentHorizontalAlignment = .left

        // Add subviews
        [profileImageView, usernameLabel, postImageView,
         likeButton, commentButton, shareButton,
         likeCountLabel, captionLabel,
         commentsPreviewLabel, addCommentButton].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),

            usernameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),

            postImageView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            postImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor),

            likeButton.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 8),
            likeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            likeButton.widthAnchor.constraint(equalToConstant: 30),
            likeButton.heightAnchor.constraint(equalToConstant: 30),

            commentButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            commentButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 12),
            commentButton.widthAnchor.constraint(equalToConstant: 30),

            shareButton.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            shareButton.leadingAnchor.constraint(equalTo: commentButton.trailingAnchor, constant: 12),
            shareButton.widthAnchor.constraint(equalToConstant: 30),

            likeCountLabel.topAnchor.constraint(equalTo: likeButton.bottomAnchor, constant: 8),
            likeCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            captionLabel.topAnchor.constraint(equalTo: likeCountLabel.bottomAnchor, constant: 4),
            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            commentsPreviewLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 4),
            commentsPreviewLabel.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            commentsPreviewLabel.trailingAnchor.constraint(equalTo: captionLabel.trailingAnchor),

            addCommentButton.topAnchor.constraint(equalTo: commentsPreviewLabel.bottomAnchor, constant: 8),
            addCommentButton.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            addCommentButton.trailingAnchor.constraint(equalTo: captionLabel.trailingAnchor),
            addCommentButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Configuration
    
    func configure(with post: Post) {
        usernameLabel.text = post.user.username
        captionLabel.text = "\(post.user.username): \(post.caption ?? "")"
        likeCountLabel.text = "\(post.likeCount) likes"
        
        // Yorumları kısa özetle göster
        if post.comments.isEmpty {
            commentsPreviewLabel.text = "No comments yet"
        } else {
            commentsPreviewLabel.text = post.comments.prefix(2).map { "\($0.user.username): \($0.text)" }.joined(separator: "\n")
        }

        if let imageUrl = URL(string: post.imageUrl) {
            downloadImage(from: imageUrl, into: postImageView)
        }
        
        /*let point  = CGPoint(x: post.tags.first?.position.x ?? 0, y: post.tags.first?.position.y ?? 0)
        addTagBalloon(at: point, username: post.tags.first?.taggedUser.username ?? "", in: postImageView)*/

        if let profileUrl = URL(string: post.user.profilePhoto), !post.user.profilePhoto.isEmpty {
            downloadImage(from: profileUrl, into: profileImageView)
        }
    }

    private func downloadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    /*func addTagBalloon(at point: CGPoint, username: String = "Who's this?", in postImgView: UIImageView ) {
        let tagBalloon = TagBalloon(username: username, position: point, in: postImgView)
        postImgView.addSubview(tagBalloon)
        tagView = tagBalloon
    }*/

}
