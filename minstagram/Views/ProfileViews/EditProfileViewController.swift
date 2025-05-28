//
//  EditProfileViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 28.04.2025.
//

import UIKit
import SDWebImage
import PhotosUI

class EditProfileViewController: UIViewController, PHPickerViewControllerDelegate {
    
    var user: UserDetail?
    weak var delegate: ProfileViewControllerDelegate?
    
    private var nameRow: EditProfileRowView!
    private var usernameRow: EditProfileRowView!
    private var bioRow: EditProfileRowView!
    
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var changePPBtn: UIButton!
    
    var currentImgUrl: String?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let user = user else { return }
        setupNavigationTitle()
        setupProfilePhoto(with: user.profilePhoto)
        setupRows(user: user)
        NotificationCenter.default.addObserver(self, selector: #selector(checkIfValuesChanged(_:)), name: .editProfileDidChange, object: nil)
    }
    
    private func setupNavigationTitle() {
        let titleLabel = UILabel()
        titleLabel.text = "Edit profile"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        titleLabel.sizeToFit()
        let titleItem = UIBarButtonItem(customView: titleLabel)
        navigationItem.leftBarButtonItems?.append(titleItem)
    }
    
    private func setupProfilePhoto(with ppUrl: String) {
        profileImgView.layer.cornerRadius = 50
        if let url = URL(string: ppUrl) {
            profileImgView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "placeholder")
            )
        }
        currentImgUrl = ppUrl
    }
    
    private func setupRows(user: UserDetail) {
        nameRow = EditProfileRowView(title: "Name", placeHolder: user.name)
        usernameRow = EditProfileRowView(title: "Username", placeHolder: user.username)
        bioRow = EditProfileRowView(title: "Bio", placeHolder: user.bio, isMultiline: true)
        
        [nameRow, usernameRow, bioRow].forEach { row in
            view.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            nameRow.topAnchor.constraint(equalTo: changePPBtn.bottomAnchor, constant: 24),
            usernameRow.topAnchor.constraint(equalTo: nameRow.bottomAnchor, constant: 24),
            bioRow.topAnchor.constraint(equalTo: usernameRow.bottomAnchor, constant: 24)
        ])

    }
    
    @IBAction func changePhoto(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) // Picker'ı kapat

        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { image, error in
            DispatchQueue.main.async {
                if let selectedImage = image as? UIImage {
                    UploadService.shared.uploadImageToBackend(image: selectedImage, folder: "profilePhotos") { imageUrl in
                        DispatchQueue.main.async {
                            guard let url = imageUrl else {
                                print("Upload failed")
                                return
                            }
                            self.profileImgView.image = selectedImage
                            self.currentImgUrl = url
                            NotificationCenter.default.post(name: .editProfileDidChange, object: nil)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func back(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func checkIfValuesChanged(_ notification: Notification) {
        guard let user = user else { return }

        let isChanged = nameRow.value != user.name ||
        usernameRow.value != user.username ||
        bioRow.value != user.bio ||
        currentImgUrl != user.profilePhoto
        
        navigationItem.rightBarButtonItem?.isEnabled = isChanged
        navigationItem.rightBarButtonItem?.tintColor = isChanged ? .systemBlue : .systemGray
    }
    
    @IBAction func saveChanges(_ sender: UIBarButtonItem) {
        guard var user = user else { return }

        user.name = nameRow.value
        user.username = usernameRow.value
        user.bio = bioRow.value
        user.profilePhoto = currentImgUrl ?? user.profilePhoto
        
        UserService.shared.updateProfile(user: user) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedUser):
                    self?.delegate?.didUpdateUserProfile(updatedUser)
                    UserManager.shared.updateActiveUser(user: updatedUser)
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
}

extension EditProfileViewController: UITextFieldDelegate {
    
}
