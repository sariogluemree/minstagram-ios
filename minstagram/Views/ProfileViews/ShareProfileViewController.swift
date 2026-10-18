//
//  ShareProfileViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 28.04.2025.
//

import UIKit
import CoreImage.CIFilterBuiltins
import SDWebImage

class ShareProfileViewController: UIViewController {

    var user: UserDetail?

    private struct ThemePalette {
        let name: String
        let primaryColor: UIColor
        let backgroundTop: UIColor
        let backgroundBottom: UIColor
    }

    private let palettes: [ThemePalette] = [
        ThemePalette(
            name: "Sunset",
            primaryColor: UIColor(red: 0.88, green: 0.19, blue: 0.42, alpha: 1.0),
            backgroundTop: UIColor(red: 0.98, green: 0.45, blue: 0.20, alpha: 1.0),
            backgroundBottom: UIColor(red: 0.83, green: 0.16, blue: 0.55, alpha: 1.0)
        ),
        ThemePalette(
            name: "Ocean",
            primaryColor: UIColor(red: 0.08, green: 0.45, blue: 0.90, alpha: 1.0),
            backgroundTop: UIColor(red: 0.15, green: 0.68, blue: 0.96, alpha: 1.0),
            backgroundBottom: UIColor(red: 0.09, green: 0.32, blue: 0.85, alpha: 1.0)
        ),
        ThemePalette(
            name: "Purple",
            primaryColor: UIColor(red: 0.48, green: 0.20, blue: 0.85, alpha: 1.0),
            backgroundTop: UIColor(red: 0.62, green: 0.31, blue: 0.95, alpha: 1.0),
            backgroundBottom: UIColor(red: 0.33, green: 0.12, blue: 0.72, alpha: 1.0)
        ),
        ThemePalette(
            name: "Emerald",
            primaryColor: UIColor(red: 0.07, green: 0.60, blue: 0.42, alpha: 1.0),
            backgroundTop: UIColor(red: 0.16, green: 0.78, blue: 0.55, alpha: 1.0),
            backgroundBottom: UIColor(red: 0.05, green: 0.45, blue: 0.35, alpha: 1.0)
        ),
        ThemePalette(
            name: "Classic",
            primaryColor: UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0),
            backgroundTop: UIColor(red: 0.28, green: 0.29, blue: 0.34, alpha: 1.0),
            backgroundBottom: UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)
        )
    ]

    private var currentPaletteIndex = 0
    private let gradientLayer = CAGradientLayer()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 28
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.22
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        v.layer.shadowRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 32
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.white.cgColor
        iv.tintColor = .systemGray3
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = .black
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let usernameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let qrImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.magnificationFilter = .nearest
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let hintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Tap card to change color"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = UIColor.white.withAlphaComponent(0.85)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let actionsContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
        v.layer.shadowRadius = 14
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let toastLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Link copied to clipboard"
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = .white
        lbl.backgroundColor = UIColor.black.withAlphaComponent(0.82)
        lbl.textAlignment = .center
        lbl.layer.cornerRadius = 18
        lbl.clipsToBounds = true
        lbl.alpha = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private var resolvedUser: UserDetail? {
        user ?? UserManager.shared.activeUser ?? UserManager.shared.loadCachedUser()
    }

    private var profileShareURLString: String {
        let username = resolvedUser?.username ?? "user"
        return "https://minstagram.app/@\(username)"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupNavigationBar()
        setupLayout()
        populateUserData()
        applyCurrentTheme(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupGradientBackground() {
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupNavigationBar() {
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "arrow.backward"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .white
        navigationItem.leftBarButtonItem = backBtn

        let titleLabel = UILabel()
        titleLabel.text = "Share Profile"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 20)
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        let colorBtn = UIBarButtonItem(
            image: UIImage(systemName: "paintpalette.fill"),
            style: .plain,
            target: self,
            action: #selector(cycleThemeTapped)
        )
        colorBtn.tintColor = .white
        navigationItem.rightBarButtonItem = colorBtn
    }

    private func setupLayout() {
        view.addSubview(cardView)
        view.addSubview(hintLabel)
        view.addSubview(actionsContainerView)
        view.addSubview(toastLabel)

        cardView.addSubview(avatarImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(usernameLabel)
        cardView.addSubview(qrImageView)

        let cardTap = UITapGestureRecognizer(target: self, action: #selector(cycleThemeTapped))
        cardView.addGestureRecognizer(cardTap)

        let shareStack = makeActionButton(
            iconName: "square.and.arrow.up",
            title: "Share profile",
            action: #selector(shareProfileTapped)
        )
        let copyStack = makeActionButton(
            iconName: "link",
            title: "Copy link",
            action: #selector(copyLinkTapped)
        )
        let downloadStack = makeActionButton(
            iconName: "qrcode",
            title: "Save QR card",
            action: #selector(saveCardTapped)
        )

        let buttonsRow = UIStackView(arrangedSubviews: [shareStack, copyStack, downloadStack])
        buttonsRow.axis = .horizontal
        buttonsRow.distribution = .fillEqually
        buttonsRow.alignment = .center
        buttonsRow.spacing = 12
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false
        actionsContainerView.addSubview(buttonsRow)

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -45),
            cardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.78),

            avatarImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            avatarImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 64),
            avatarImageView.heightAnchor.constraint(equalToConstant: 64),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            usernameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            qrImageView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 18),
            qrImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            qrImageView.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.68),
            qrImageView.heightAnchor.constraint(equalTo: qrImageView.widthAnchor),
            qrImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -26),

            hintLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 14),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            actionsContainerView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 20),
            actionsContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            actionsContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            actionsContainerView.heightAnchor.constraint(equalToConstant: 92),

            buttonsRow.topAnchor.constraint(equalTo: actionsContainerView.topAnchor, constant: 12),
            buttonsRow.leadingAnchor.constraint(equalTo: actionsContainerView.leadingAnchor, constant: 12),
            buttonsRow.trailingAnchor.constraint(equalTo: actionsContainerView.trailingAnchor, constant: -12),
            buttonsRow.bottomAnchor.constraint(equalTo: actionsContainerView.bottomAnchor, constant: -12),

            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.widthAnchor.constraint(equalToConstant: 210),
            toastLabel.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func makeActionButton(iconName: String, title: String, action: Selector) -> UIView {
        let container = UIControl()
        container.addTarget(self, action: action, for: .touchUpInside)
        container.translatesAutoresizingMaskIntoConstraints = false

        let circleView = UIView()
        circleView.backgroundColor = UIColor(white: 0.94, alpha: 1.0)
        circleView.layer.cornerRadius = 22
        circleView.isUserInteractionEnabled = false
        circleView.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = .black
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        circleView.addSubview(iconView)

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(circleView)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: container.topAnchor),
            circleView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 44),
            circleView.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            label.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func populateUserData() {
        guard let user = resolvedUser else { return }
        nameLabel.text = user.name.isEmpty ? user.username : user.name
        usernameLabel.text = "@\(user.username.uppercased())"

        if !user.profilePhoto.isEmpty, let url = URL(string: user.profilePhoto) {
            avatarImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "person.crop.circle.fill")
            )
        } else {
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }

    private func applyCurrentTheme(animated: Bool) {
        let palette = palettes[currentPaletteIndex]
        let changes = {
            self.gradientLayer.colors = [
                palette.backgroundTop.cgColor,
                palette.backgroundBottom.cgColor
            ]
            self.usernameLabel.textColor = palette.primaryColor
            self.qrImageView.image = self.generateQRCode(
                from: self.profileShareURLString,
                tintColor: palette.primaryColor
            )
        }

        if animated {
            UIView.transition(with: cardView, duration: 0.25, options: .transitionCrossDissolve, animations: changes)
        } else {
            changes()
        }
    }

    private func generateQRCode(from string: String, tintColor: UIColor) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = outputImage
        colorFilter.color0 = CIColor(color: tintColor)
        colorFilter.color1 = CIColor(color: .white)

        guard let coloredImage = colorFilter.outputImage else { return nil }

        let scale: CGFloat = 12.0
        let transformed = coloredImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func renderCardAsImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: cardView.bounds)
        return renderer.image { context in
            cardView.layer.render(in: context.cgContext)
        }
    }

    private func showToast(_ message: String) {
        toastLabel.text = message
        UIView.animate(withDuration: 0.25) {
            self.toastLabel.alpha = 1.0
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 1.6, options: []) {
                self.toastLabel.alpha = 0.0
            }
        }
    }

    @objc private func cycleThemeTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        currentPaletteIndex = (currentPaletteIndex + 1) % palettes.count
        applyCurrentTheme(animated: true)
    }

    @objc private func shareProfileTapped() {
        let cardImage = renderCardAsImage()
        let shareText = "Check out @\(resolvedUser?.username ?? "my")'s profile on Minstagram: \(profileShareURLString)"
        let activityVC = UIActivityViewController(activityItems: [cardImage, shareText], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = actionsContainerView
            popover.sourceRect = actionsContainerView.bounds
        }
        present(activityVC, animated: true)
    }

    @objc private func copyLinkTapped() {
        UIPasteboard.general.string = profileShareURLString
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        showToast("Link copied to clipboard")
    }

    @objc private func saveCardTapped() {
        let cardImage = renderCardAsImage()
        let activityVC = UIActivityViewController(activityItems: [cardImage], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = actionsContainerView
            popover.sourceRect = actionsContainerView.bounds
        }
        present(activityVC, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
