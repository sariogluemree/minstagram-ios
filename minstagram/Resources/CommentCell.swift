//
//  CommentCell.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 14.05.2025.
//

import UIKit

class CommentCell: UITableViewCell {
    
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with comment: Comment) {
        profileImgView.layer.cornerRadius = profileImgView.frame.height / 2
        profileImgView.clipsToBounds = true
        profileImgView.backgroundColor = .lightGray
        if let profileUrl = URL(string: comment.user.profilePhoto), !comment.user.profilePhoto.isEmpty {
            loadImage(from: profileUrl, into: profileImgView)
        }
        usernameLabel.text = comment.user.username
        commentLabel.text = comment.text
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        imageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "placeholder")
        )
    }

}
