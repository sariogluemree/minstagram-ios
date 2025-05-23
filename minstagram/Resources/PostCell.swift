//
//  PostCell.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 16.04.2025.
//

import UIKit
import SDWebImage

class PostCell: UITableViewCell, UIActionSheetDelegate {
    
    var post: Post?
    
    @IBOutlet weak var optionsButton: UIButton!
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
    @IBOutlet weak var timeLabel: UILabel!
    
    var onLikeTapped: (() -> Void)?
    var onCommentTapped: (() -> Void)?
    var onSaveTapped: (() -> Void)?
    var onGoProfileTapped: (() -> Void)?
    var onCaptionTapped: (() -> Void)?
    var onOptionsTapped: (() -> Void)?
    
    var isExpandedCaption: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupTapGesture()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        for subview in postImageView.subviews {
            subview.removeFromSuperview()
        }
        optionsButton.isHidden = false
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.image = UIImage(named: "placeholder")
        postImageView.sd_cancelCurrentImageLoad()
        postImageView.image = UIImage(named: "placeholder")
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .black
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = .black
    }
    
    private func setupTapGesture() {
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProfileTap))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(profileTapGesture)
        usernameLabel.isUserInteractionEnabled = true
        usernameLabel.addGestureRecognizer(profileTapGesture)
        
        let captionTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCaptionTap))
        captionLabel.isUserInteractionEnabled = true
        captionLabel.addGestureRecognizer(captionTapGesture)
        
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCommentTap))
        commentsLabel.isUserInteractionEnabled = true
        commentsLabel.addGestureRecognizer(commentTapGesture)
    }

    private func setupUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.backgroundColor = .lightGray
        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
    }
    
    @IBAction func optionsButtonTapped(_ sender: UIButton) {
        onOptionsTapped?()
    }
    
    @IBAction func toggleTagHidden(_ sender: UIButton) {
        for tagBalloon in postImageView.subviews {
            tagBalloon.isHidden.toggle()
        }
    }
    
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        onLikeTapped?()
    }
    
    @IBAction func commentButtonTapped(_ sender: UIButton) {
        onCommentTapped?()
    }
    
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        onSaveTapped?()
    }
    
    @objc private func handleProfileTap() {
        onGoProfileTapped?()
    }
    
    @objc private func handleCommentTap() {
        onCommentTapped?()
    }
    
    @objc private func handleCaptionTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        guard let attributedText = label.attributedText else { return }

        let location = gesture.location(in: label)

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let index = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if let post = post {
            let username = post.user.username
            let fullText = username + " " + (post.caption ?? "")
            let usernameRange = (fullText as NSString).range(of: username)
            if NSLocationInRange(index, usernameRange) {
                onGoProfileTapped?()
                return
            }
        }
        
        onCaptionTapped?()
    }
    
    func configure(with post: Post, isTruncated: Bool) {
        
        if let activeUser = UserManager.shared.activeUser, activeUser.username != post.user.username {
            optionsButton.isHidden = true
        }
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
        
        let username = post.user.username
        let caption = post.caption ?? ""
        let fullText = "\(username) \(caption)"
        var attributedCaption = NSMutableAttributedString()
        var postFixRange = NSRange()
        if fullText.count > 70 {
            if !isTruncated {
                let truncatedText = fullText.prefix(70) + "... more"
                postFixRange = (truncatedText as NSString).range(of: "more")
                let truncatedCaption = String(truncatedText)
                attributedCaption = NSMutableAttributedString(string: truncatedCaption)
                isExpandedCaption = false
            } else {
                let expandedText = fullText + " less"
                postFixRange = (expandedText as NSString).range(of: "less")
                attributedCaption = NSMutableAttributedString(string: expandedText)
                isExpandedCaption = true
            }
            let postFixFont = UIFont.systemFont(ofSize: captionLabel.font.pointSize)
            attributedCaption.addAttributes([.font: postFixFont, .foregroundColor: UIColor.gray], range: postFixRange)
        } else {
            let originalCaption = fullText
            attributedCaption = NSMutableAttributedString(string: originalCaption)
        }
        let usernameRange = (fullText as NSString).range(of: username)
        let boldFont = UIFont.boldSystemFont(ofSize: captionLabel.font.pointSize)
        attributedCaption.addAttribute(.font, value: boldFont, range: usernameRange)
        captionLabel.attributedText = attributedCaption
        
        let comments = post.comments.prefix(2)
        let attributedComments = NSMutableAttributedString()
        let normalAttrs: [NSAttributedString.Key: Any] = [.font: commentsLabel.font ?? UIFont.systemFont(ofSize: 14)]
        if comments.isEmpty {
            attributedComments.append(NSAttributedString(string: "No comments", attributes: normalAttrs))
        } else {
            let boldAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: commentsLabel.font.pointSize)]
            for comment in comments {
                let username = comment.user.username
                let text = comment.text
                let boldUsername = NSAttributedString(string: "\(username): ", attributes: boldAttrs)
                let normalText = NSAttributedString(string: "\(text)\n", attributes: normalAttrs)
                attributedComments.append(boldUsername)
                attributedComments.append(normalText)
            }
            if attributedComments.length > 0 {
                attributedComments.deleteCharacters(in: NSRange(location: attributedComments.length - 1, length: 1))
            }
        }
        commentsLabel.attributedText = attributedComments

        timeLabel.text = DateHelper.timeAgo(from: post.createdAt)
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
        imageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "placeholder")
        )
    }
}

