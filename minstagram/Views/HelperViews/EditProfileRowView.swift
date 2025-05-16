//
//  EditProfileRowView.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 3.05.2025.
//

import UIKit

class EditProfileRowView: UIView, UITextViewDelegate {
    
    private let titleLabel = UILabel()
    private var textField: UITextField?
    private var textView: UITextView?
    private var textViewHeightConstraint: NSLayoutConstraint?
    var value: String {
        return textView?.text ?? textField?.text ?? ""
    }

    
    init(title: String, placeHolder: String, isMultiline: Bool = false) {
        super.init(frame: .zero)
        setupView(title: title, placeHolder: placeHolder, isMultiline: isMultiline)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(title: String, placeHolder: String, isMultiline: Bool) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(tapGesture)
        
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .gray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
        
        let underline = UIView()
        underline.backgroundColor = .systemGray4
        underline.translatesAutoresizingMaskIntoConstraints = false
        addSubview(underline)
        NSLayoutConstraint.activate([
            underline.heightAnchor.constraint(equalToConstant: 1),
            underline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            underline.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            underline.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        
        if isMultiline {
            let tv = UITextView()
            tv.text = placeHolder
            tv.font = UIFont.systemFont(ofSize: 16)
            tv.isScrollEnabled = false
            tv.backgroundColor = .clear
            tv.delegate = self
            tv.translatesAutoresizingMaskIntoConstraints = false
            addSubview(tv)
            textView = tv

            textViewHeightConstraint = tv.heightAnchor.constraint(equalToConstant: 40)
            textViewHeightConstraint?.isActive = true

            NSLayoutConstraint.activate([
                tv.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                tv.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                tv.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                tv.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            let tf = UITextField()
            tf.text = placeHolder
            tf.borderStyle = .none
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            addSubview(tf)
            textField = tf

            NSLayoutConstraint.activate([
                tf.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                tf.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                tf.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                tf.bottomAnchor.constraint(equalTo: bottomAnchor),
                self.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
    }
    
    @objc private func tapped() {
        print("row tapped")
    }
    
    @objc private func textFieldDidChange(_ sender: UITextField) {
        NotificationCenter.default.post(name: .editProfileDidChange, object: self)
    }

    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        textViewHeightConstraint?.constant = estimatedSize.height
        layoutIfNeeded()

        NotificationCenter.default.post(name: .editProfileDidChange, object: self)
    }

    
}

extension Notification.Name {
    static let editProfileDidChange = Notification.Name("editProfileDidChange")
}
