//
//  RowViews.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 8.03.2025.
//

import UIKit

enum RowType {
    case settings
    case taggedUser
}

class RowView: UIView {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let actionImgView = UIImageView()
    private var tapAction: (() -> Void)?
    
    init(icon: UIImage?, title: String, rowType: RowType, action: @escaping () -> Void) {
        super.init(frame: .zero)
        self.tapAction = action
        setupView(icon: icon, title: title, rowType: rowType)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(icon: UIImage?, title: String, rowType: RowType) {
        self.translatesAutoresizingMaskIntoConstraints = false
        let targetView: UIView = (rowType == .settings) ? self : actionImgView
        targetView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        targetView.addGestureRecognizer(tapGesture)
        
        iconImageView.image = icon
        iconImageView.tintColor = .gray
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let actionImg = (rowType == .settings) ? UIImage(systemName: "chevron.right") : UIImage(systemName: "xmark")
        actionImgView.image = actionImg
        actionImgView.tintColor = .gray
        actionImgView.contentMode = .scaleAspectFit
        actionImgView.translatesAutoresizingMaskIntoConstraints = false
        
        // Subview'leri ekle
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(actionImgView)
        
        // Auto Layout
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 50),
            
            iconImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            
            actionImgView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            actionImgView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            actionImgView.widthAnchor.constraint(equalToConstant: 20),
            actionImgView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    @objc private func tapped() {
        tapAction?()
    }
}
