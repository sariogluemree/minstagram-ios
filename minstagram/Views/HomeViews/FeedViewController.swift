//
//  ViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 19.02.2025.
//

import UIKit
import PhotosUI

class FeedViewController: UIViewController, PHPickerViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleLabel = UILabel()
        titleLabel.text = "Minstagram"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        titleLabel.sizeToFit()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        
    }

    @IBAction func newPost(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true) // 📌 Picker direkt olarak anasayfanın üzerine açılacak
    }

    // Kullanıcı bir fotoğraf seçtiğinde burası çalışır
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) // Picker'ı kapat

        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { image, error in
            DispatchQueue.main.async {
                if let selectedImage = image as? UIImage {
                    let sb = UIStoryboard(name: "NewPost", bundle: nil)
                    if let nav = sb.instantiateViewController(withIdentifier: "NewPostNavigationController") as? UINavigationController,
                       let vc = nav.viewControllers.first as? PostOptionsViewController {
                        vc.selectedImage = selectedImage
                        self.view.window?.rootViewController = nav
                        self.view.window?.makeKeyAndVisible()
                    }
                }
            }
        }
    }
    
}

