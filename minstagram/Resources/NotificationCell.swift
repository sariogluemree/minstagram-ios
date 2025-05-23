//
//  NotificationCell.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 21.05.2025.
//

import UIKit
import SDWebImage

class NotificationCell: UITableViewCell {
    
    @IBOutlet weak var ppImgView: UIImageView!
    @IBOutlet weak var notificationMessage: UILabel!
    
    var notification: AppNotification?
    
    var onGoProfileTapped: (() -> Void)?
    var onCellTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
        setupTapGesture()
    }
    
    override func prepareForReuse() {
        ppImgView.sd_cancelCurrentImageLoad()
        ppImgView.image = UIImage(named: "placeholder")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setupUI() {
        ppImgView.layer.cornerRadius = ppImgView.frame.height / 2
        ppImgView.backgroundColor = .lightGray
        ppImgView.contentMode = .scaleAspectFill
        ppImgView.clipsToBounds = true
    }
    
    private func setupTapGesture() {
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePPTap))
        ppImgView.isUserInteractionEnabled = true
        ppImgView.addGestureRecognizer(profileTapGesture)
        
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleUsernameTap(_:)))
        notificationMessage.isUserInteractionEnabled = true
        notificationMessage.addGestureRecognizer(usernameTapGesture)
        
    }
    
    @objc private func handlePPTap() {
        onGoProfileTapped?()
    }
        
    @objc private func handleUsernameTap(_ gesture: UITapGestureRecognizer) {
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
        
        if let notification = notification {
            let username = notification.sender.username
            let fullText = notificationMessage.text ?? ""
            let usernameRange = (fullText as NSString).range(of: username)
            if NSLocationInRange(index, usernameRange) {
                onGoProfileTapped?()
                return
            }
        }
        onCellTapped?()
    }
    
    
    func configure(with notification: AppNotification) {
        if let profileUrl = URL(string: notification.sender.profilePhoto), !notification.sender.profilePhoto.isEmpty {
            loadImage(from: profileUrl, into: ppImgView)
        }
        
        switch notification.type {
        case .follow:
            notificationMessage.text = "\(notification.sender.username) started following you."
        case .like:
            notificationMessage.text = "\(notification.sender.username) liked your post."
        case .comment:
            if let comment = notification.comment {
                notificationMessage.text = "\(notification.sender.username) commented on your post: \(comment.text)"
            }
        case .tag:
            notificationMessage.text = "\(notification.sender.username) tagged you in a post."
        }
        
        var attributedMessage = NSMutableAttributedString()
        let fullText = notificationMessage.text ?? ""
        attributedMessage = NSMutableAttributedString(string: fullText)
        let usernameRange = (fullText as NSString).range(of: notification.sender.username)
        let boldFont = UIFont.boldSystemFont(ofSize: notificationMessage.font.pointSize)
        attributedMessage.addAttribute(.font, value: boldFont, range: usernameRange)
        notificationMessage.attributedText = attributedMessage
        
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        imageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "placeholder")
        )
    }

}
