//
//  PostOptionsViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 8.03.2025.
//

import UIKit

class PostOptionsViewController : UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var newPostImgView: UIImageView!
    @IBOutlet weak var captionOkayBtn: UIBarButtonItem!
    let captionTextView = UITextView()
    
    var selectedImage: UIImage?
    var caption: String?
    var debounceTimer: Timer?
    
    var tagList : [Tag] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tagList.count == 1 {
            if let tag = tagList.first {
                print(tag.taggedUser.username)
            }
        } else if tagList.count > 1 {
            print(tagList.count)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captionTextView.resignFirstResponder()
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "New Post"
        let titleLabel = UILabel()
        titleLabel.text = "New Post"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        navigationItem.titleView = titleLabel
        
        captionOkayBtn.isHidden = true
        
        captionTextView.translatesAutoresizingMaskIntoConstraints = false
        captionTextView.text = "Add a caption..."
        captionTextView.font = UIFont.systemFont(ofSize: 16)
        captionTextView.isScrollEnabled = false
        captionTextView.delegate = self
        captionTextView.backgroundColor = .lightGray
        view.addSubview(captionTextView)
        NSLayoutConstraint.activate([
            captionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captionTextView.topAnchor.constraint(equalTo: newPostImgView.bottomAnchor, constant: 20),
            captionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
        
        if let newPostImg = selectedImage {
            newPostImgView.image = newPostImg
            
            let tagPeopleRow = RowView(icon: UIImage(systemName: "person.circle.fill"), title: "Tag People", rowType: RowType.settings) {
                let sb = UIStoryboard(name: "NewPost", bundle: nil)
                if let vc = sb.instantiateViewController(withIdentifier: "TagPeopleViewController") as? TagPeopleViewController {
                    vc.postImg = newPostImg
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            view.addSubview(tagPeopleRow)
            tagPeopleRow.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tagPeopleRow.topAnchor.constraint(equalTo: captionTextView.bottomAnchor, constant: 20),
                tagPeopleRow.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
                tagPeopleRow.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            ])
            
        }
    
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: self.view)
        if !newPostImgView.frame.contains(touchPoint) {
            self.view.endEditing(true)
        }
    }
    
    @IBAction func captionOkPressed(_ sender: UIBarButtonItem) {
        textViewDidEndEditing(captionTextView)
    }
    
    @IBAction func shareBtnPressed(_ sender: UIButton) {
        
        guard let image = newPostImgView.image else {
            print("No image to upload")
            return
        }
    
        UploadService.shared.uploadImageToBackend(image: image) { imageUrl in
            guard let url = imageUrl else {
                print("Upload failed")
                return
            }
            
            let caption = self.caption ?? ""
            let tags = self.tagList

            PostService.shared.createPost(imageUrl: url, caption: caption, tags: tags) { result in
                switch result {
                case .success(let post):
                    print(post)
                    print("Post created successfully!")
                    DispatchQueue.main.async {
                        let sb = UIStoryboard(name: "Main", bundle: nil)
                        if let nav = sb.instantiateViewController(withIdentifier: "FeedNavigationController") as? UINavigationController {
                            self.view.window?.rootViewController = nav
                            self.view.window?.makeKeyAndVisible()
                        }
                    }
                case .failure(let error):
                    print("Failed to create post: \(error)")
                }
            }
        }
        
    }
    
    // MARK: - TextView Methods
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Add a caption..." {
            textView.text = ""
        }
        captionOkayBtn.isHidden = false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text, !text.isEmpty && text != "Add a caption..." {
            caption = text
        } else {
            textView.text = "Add a caption..."
        }
        captionOkayBtn.isHidden = true
        view.endEditing(true)
    }

    @IBAction func backBtnPressed(_ sender: UIBarButtonItem) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let nav = sb.instantiateViewController(withIdentifier: "FeedNavigationController") as? UINavigationController {
            self.view.window?.rootViewController = nav
            self.view.window?.makeKeyAndVisible()
        }
    }
    
}
