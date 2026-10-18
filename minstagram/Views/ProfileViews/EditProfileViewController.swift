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
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.tintColor = .systemGray
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
        profileImgView.translatesAutoresizingMaskIntoConstraints = false
        changePPBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImgView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            profileImgView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImgView.widthAnchor.constraint(equalToConstant: 100),
            profileImgView.heightAnchor.constraint(equalToConstant: 100),
            changePPBtn.topAnchor.constraint(equalTo: profileImgView.bottomAnchor, constant: 12),
            changePPBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        profileImgView.layer.cornerRadius = 50
        profileImgView.clipsToBounds = true
        profileImgView.tintColor = .systemGray
        if !ppUrl.isEmpty, let url = URL(string: ppUrl) {
            profileImgView.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "person.crop.circle.fill")
            )
        } else {
            profileImgView.image = UIImage(systemName: "person.crop.circle.fill")
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
            guard let selectedImage = image as? UIImage else { return }
            Task { @MainActor [weak self] in
                do {
                    let form = try MultipartFormData.image(selectedImage, type: UploadFolder.profilePhotos)
                    let response = try await NetworkManager.shared.upload(UploadEndpoint.image, form: form, as: UploadResponse.self)
                    self?.profileImgView.image = selectedImage
                    self?.currentImgUrl = response.url
                    NotificationCenter.default.post(name: .editProfileDidChange, object: nil)
                } catch {
                    self?.showError(error)
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
        
        Task { [weak self] in
            do {
                let updatedUser = try await NetworkManager.shared.request(UserEndpoint.update(UpdateProfileRequest(user: user)), as: UserDetail.self)
                self?.delegate?.didUpdateUserProfile(updatedUser)
                UserManager.shared.updateActiveUser(user: updatedUser)
                self?.navigationController?.popViewController(animated: true)
            } catch {
                self?.showError(error, title: "Error")
            }
        }
    }
    
}

extension EditProfileViewController: UITextFieldDelegate {
    
}
