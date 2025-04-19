//
//  ViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 19.02.2025.
//

import UIKit
import PhotosUI

class FeedViewController: UIViewController, PHPickerViewControllerDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleLabel = UILabel()
        titleLabel.text = "Minstagram"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        titleLabel.sizeToFit()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        
        let nib = UINib(nibName: "PostCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "PostCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 600
        
        PostService.shared.fetchAllPosts { result in
            switch(result) {
            case .success(let posts):
                self.posts = posts
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching posts: \(error)")
            }
        }
        
    }
    
    func refreshPost(withId id: String, at indexPath: IndexPath) {
        PostService.shared.fetchPost(byId: id) { result in
            switch result {
            case .success(let updatedPost):
                DispatchQueue.main.async {
                    self.posts[indexPath.row] = updatedPost
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            case .failure(let error):
                print(error)
            }
        }
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

extension FeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let post = posts[indexPath.row]
        
        cell.configure(with: post)
        
        cell.onLikeTapped = {
            if post.isLiked {
                LikeService.shared.unlikePost(postId: post.id) { result in
                    switch result {
                    case .success(let message):
                        print(message)
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            } else {
                LikeService.shared.likePost(postId: post.id) { result in
                    switch result {
                    case .success(_):
                        print("Post liked")
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        cell.onSaveTapped = {
            if post.isSaved {
                SavedPostService.shared.unsavePost(postId: post.id) { result in
                    switch result {
                    case .success(let message):
                        print(message)
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            } else {
                SavedPostService.shared.savePost(postId: post.id) { result in
                    switch result {
                    case .success(_):
                        print("Post saved")
                        self.refreshPost(withId: post.id, at: indexPath)
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

}


