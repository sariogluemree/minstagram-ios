//
//  ProfileActionView.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 24.04.2025.
//

import UIKit

protocol ProfileActionView: UIView {
    var delegate: ProfileActionViewDelegate? { get set }
    func setupUI()
}

protocol ProfileActionViewDelegate: AnyObject {
    func didTapEditProfile()
    func didTapShareProfile()
    func didTapShowRecommendations()
    func didTapUnfollow()
    func didTapMessage()
    func didTapFollow()
}

// MARK: - Active User's Profile

class OwnProfileActionView: UIView, ProfileActionView {
    
    weak var delegate: ProfileActionViewDelegate?
    
    private lazy var btnContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private lazy var editProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit Profile", for: .normal)
        button.backgroundColor = .systemGray5
        button.tintColor = .black
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var shareProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share Profile", for: .normal)
        button.backgroundColor = .systemGray5
        button.tintColor = .black
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(shareProfileTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var recommendationsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        button.backgroundColor = .systemGray5
        button.tintColor = .black
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(recommendationsTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        addSubview(btnContainerView)
        btnContainerView.addSubview(stackView)
        btnContainerView.addSubview(recommendationsButton)
        stackView.addArrangedSubview(editProfileButton)
        stackView.addArrangedSubview(shareProfileButton)
        
        // Auto Layout constraints
        btnContainerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        recommendationsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btnContainerView.topAnchor.constraint(equalTo: topAnchor),
            btnContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            btnContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            btnContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.topAnchor.constraint(equalTo: btnContainerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: btnContainerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: recommendationsButton.leadingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: btnContainerView.bottomAnchor),
            recommendationsButton.topAnchor.constraint(equalTo: btnContainerView.topAnchor),
            recommendationsButton.trailingAnchor.constraint(equalTo: btnContainerView.trailingAnchor),
            recommendationsButton.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8),
            recommendationsButton.bottomAnchor.constraint(equalTo: btnContainerView.bottomAnchor),
            recommendationsButton.widthAnchor.constraint(equalToConstant: 35),
            recommendationsButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    @objc private func editProfileTapped() {
        delegate?.didTapEditProfile()
    }
    
    @objc private func shareProfileTapped() {
        delegate?.didTapShareProfile()
    }
    
    @objc private func recommendationsTapped() {
        delegate?.didTapShowRecommendations()
    }
}

// MARK: - Unfollowed Profile

class UnfollowedProfileActionView: UIView, ProfileActionView {
    weak var delegate: ProfileActionViewDelegate?
    
    private lazy var followButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Follow", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        addSubview(followButton)
        
        followButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            followButton.topAnchor.constraint(equalTo: topAnchor),
            followButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            followButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            followButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            followButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    @objc private func followTapped() {
        delegate?.didTapFollow()
    }
}

// MARK: - Followed Profile

class FollowedProfileActionView: UIView, ProfileActionView {
    weak var delegate: ProfileActionViewDelegate?
    
    private lazy var btnContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private lazy var unfollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Unfollow", for: .normal)
        button.backgroundColor = .systemGray5
        button.tintColor = .black
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(unfollowTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var messageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Message", for: .normal)
        button.backgroundColor = .systemGray5
        button.tintColor = .black
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(goToDirectMessages), for: .touchUpInside)
        return button
    }()
    
    private lazy var recommendationsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        button.backgroundColor = .systemGray5
        button.tintColor = .black
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(recommendationsTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    } 
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        addSubview(btnContainerView)
        btnContainerView.addSubview(stackView)
        btnContainerView.addSubview(recommendationsButton)
        stackView.addArrangedSubview(unfollowButton)
        stackView.addArrangedSubview(messageButton)
        
        btnContainerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        recommendationsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btnContainerView.topAnchor.constraint(equalTo: topAnchor),
            btnContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            btnContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            btnContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.topAnchor.constraint(equalTo: btnContainerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: btnContainerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: recommendationsButton.leadingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: btnContainerView.bottomAnchor),
            recommendationsButton.topAnchor.constraint(equalTo: btnContainerView.topAnchor),
            recommendationsButton.trailingAnchor.constraint(equalTo: btnContainerView.trailingAnchor),
            recommendationsButton.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8),
            recommendationsButton.bottomAnchor.constraint(equalTo: btnContainerView.bottomAnchor),
            recommendationsButton.widthAnchor.constraint(equalToConstant: 35),
            recommendationsButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    @objc private func unfollowTapped() {
        delegate?.didTapUnfollow()
    }
    
    @objc private func goToDirectMessages() {
        delegate?.didTapMessage()
    }
    
    @objc private func recommendationsTapped() {
        delegate?.didTapShowRecommendations()
    }
}
