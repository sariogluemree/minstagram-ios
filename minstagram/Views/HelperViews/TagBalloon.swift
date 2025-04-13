//
//  TagBalloon.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 31.03.2025.
//

import UIKit

struct Tag: Codable {
    let taggedUser: PostUser
    let position: Position
}

struct Position: Codable {
    let x: Double
    let y: Double
}

class TagBalloon: UIView {
    private let padding: CGFloat = 10
    private let maxWidth: CGFloat = 200
    private let label = UILabel()
    
    init(username: String, position: CGPoint, in parentView: UIView) {
        super.init(frame: .zero)
        setupLabel(username: username)
        setupView(position: position, in: parentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel(username: String) {
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = username
        label.numberOfLines = 1
        label.sizeToFit()
    }
    
    private func setupView(position: CGPoint, in parentView: UIView) {
        let textWidth = min(label.frame.width + padding * 2, maxWidth)
        let textHeight = label.frame.height + padding
        
        let x: CGFloat = (position.x + textWidth < parentView.frame.width) ? position.x : position.x - textWidth
        self.frame = CGRect(x: x, y: position.y, width: textWidth, height: textHeight)
        
        self.backgroundColor = .gray
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 0.5
        self.layer.masksToBounds = true
        
        label.frame = CGRect(x: padding, y: padding / 2, width: textWidth - padding * 2, height: textHeight - padding)
        self.addSubview(label)
    }
    
    func updateUsername(_ username: String, in parentView: UIView) {
        label.text = username
        label.sizeToFit()
        
        let textWidth = min(label.frame.width + padding * 2, maxWidth)
        let textHeight = label.frame.height + padding
        
        let tagX = self.frame.origin.x
        let x: CGFloat = (tagX + textWidth < parentView.frame.width) ? tagX : tagX - textWidth
        
        UIView.animate(withDuration: 0.3) {
            self.frame = CGRect(x: x, y: self.frame.origin.y, width: textWidth, height: textHeight)
            self.label.frame = CGRect(x: self.padding, y: self.padding / 2, width: textWidth - self.padding * 2, height: textHeight - self.padding)
        }
    }
    
}
