//
//  UserCell.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 22.04.2025.
//

import UIKit
import SDWebImage

class UserCell: UITableViewCell {
    
    var onActionTapped: (() -> Void)?
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        btn.backgroundColor = .systemGray5
        btn.setTitleColor(.label, for: .normal)
        btn.layer.cornerRadius = 8
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        btn.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        actionButton.isHidden = true
        onActionTapped = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        profileImageView.tintColor = .systemGray
        contentView.addSubview(profileImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(actionButton)
        
        let minHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        minHeightConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            minHeightConstraint,
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            usernameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -12),
            
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with user: PostUser, actionTitle: String? = nil, onActionTapped: (() -> Void)? = nil) {
        usernameLabel.text = user.username
        if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
            profileImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle.fill"))
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
        
        if let actionTitle = actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.isHidden = false
            self.onActionTapped = onActionTapped
        } else {
            actionButton.isHidden = true
            self.onActionTapped = nil
        }
    }
    
    @objc private func actionButtonTapped() {
        onActionTapped?()
    }
}

