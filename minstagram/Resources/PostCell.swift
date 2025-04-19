//
//  PostCell.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 16.04.2025.
//

import UIKit

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

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .lightGray
        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
    }

    func configure(with post: Post) {
        usernameLabel.text = post.user.username
        captionLabel.text = "\(post.user.username): \(post.caption ?? "")"
        likeCountLabel.text = "\(post.likeCount) likes"
        let comments = post.comments.prefix(2).map { "\($0.user.username): \($0.text)" }.joined(separator: "\n")
        commentsLabel.text = comments.isEmpty ? "No comments" : comments

        if let imageUrl = URL(string: post.imageUrl) {
            loadImage(from: imageUrl, into: postImageView)
        }
        if let profileUrl = URL(string: post.user.profilePhoto), !post.user.profilePhoto.isEmpty {
            loadImage(from: profileUrl, into: profileImageView)
        }
    }

    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
}

