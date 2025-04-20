//
//  PostCell.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 16.04.2025.
//

import UIKit
import SDWebImage

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var taggedPeopleIcon: UIButton!
    
    var onLikeTapped: (() -> Void)?
    var onSaveTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        for subview in postImageView.subviews {
            subview.removeFromSuperview()
        }
        postImageView.sd_cancelCurrentImageLoad()
        postImageView.image = UIImage(named: "placeholder")
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .black
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = .black
    }

    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .lightGray
        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
    }
    
    @IBAction func toggleTagHidden(_ sender: UIButton) {
        for tagBalloon in postImageView.subviews {
            tagBalloon.isHidden.toggle()
        }
    }
    
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        onLikeTapped?()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        onSaveTapped?()
    }
    
    
    func configure(with post: Post) {
        if let profileUrl = URL(string: post.user.profilePhoto), !post.user.profilePhoto.isEmpty {
            loadImage(from: profileUrl, into: profileImageView)
        }
        usernameLabel.text = post.user.username
        if let imageUrl = URL(string: post.imageUrl) {
            loadImage(from: imageUrl, into: postImageView)
        }
        taggedPeopleIcon.isHidden = true
        if !post.tags.isEmpty {
            taggedPeopleIcon.isHidden = false
            for tag in post.tags {
                let point = CGPoint(x: tag.position.x, y: tag.position.y)
                addTagBalloon(at: point, username: tag.taggedUser.username, in: postImageView)
            }
        }

        likeCountLabel.text = "\(post.likeCount) likes"
        captionLabel.text = "\(post.user.username): \(post.caption ?? "")"
        let comments = post.comments.prefix(2).map { "\($0.user.username): \($0.text)" }.joined(separator: "\n")
        commentsLabel.text = comments.isEmpty ? "No comments" : comments
        if post.isLiked {
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeButton.tintColor = .red
        }
        if post.isSaved {
            bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            bookmarkButton.tintColor = .black
        }
    }
    
    func addTagBalloon(at point: CGPoint, username: String, in postImgView: UIImageView ) {
        let tagBalloon = TagBalloon(username: username, position: point, in: postImgView)
        tagBalloon.isHidden = true
        postImgView.addSubview(tagBalloon)
    }

    private func loadImage(from url: URL, into imageView: UIImageView) {
        postImageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "placeholder")
        )
    }
}

