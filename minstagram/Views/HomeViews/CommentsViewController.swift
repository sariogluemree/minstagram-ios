//
//  CommentsViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 14.05.2025.
//

import UIKit

protocol CommentsViewControllerDelegate: AnyObject {
    func commentsViewController(_ controller: CommentsViewController, commentAddedAt index: IndexPath)
}

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    var delegate: CommentsViewControllerDelegate?
    var post: Post?
    var postIndex: IndexPath?
    var comments = [Comment]()
    var commentIndex: Int?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addCommentView: UIView!
    @IBOutlet weak var ppImgView: UIImageView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var shareCommentButton: UIButton!
    @IBOutlet weak var addCommentViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let activeUser = UserManager.shared.activeUser else {return}
        self.title = "Comments"
        guard let post = post else {return}
        comments = post.comments
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.lightGray
        DispatchQueue.main.async {
            if let commentIndex = self.commentIndex {
                let commentIndexPath = IndexPath(row: commentIndex, section: 0)
                self.tableView.scrollToRow(at: commentIndexPath, at: .top, animated: true)
                let cell = self.tableView.cellForRow(at: commentIndexPath) as! CommentCell
                cell.selectionStyle = .default
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.tableView.selectRow(at: commentIndexPath, animated: true, scrollPosition: .top)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.tableView.deselectRow(at: commentIndexPath, animated: true)
                        cell.selectionStyle = .none
                    }
                }
            }
        }
        addCommentView.layer.borderWidth = 0.2
        addCommentView.layer.borderColor = UIColor.lightGray.cgColor
        addCommentView.clipsToBounds = true
        commentTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        ppImgView.layer.cornerRadius = ppImgView.frame.height / 2
        ppImgView.clipsToBounds = true
        ppImgView.backgroundColor = .lightGray
        if let profileUrl = URL(string: activeUser.profilePhoto), !activeUser.profilePhoto.isEmpty {
            loadImage(from: profileUrl, into: ppImgView)
        }
        shareCommentButton.isUserInteractionEnabled = false
        shareCommentButton.tintColor = .systemGray
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let bottomInset = self.view.safeAreaInsets.bottom
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
           let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            let keyboardHeight = keyboardFrame.height
            self.addCommentViewBottomConstraint.constant = -keyboardHeight + bottomInset
            print("keyboardHeight: \(keyboardHeight)")
            print(addCommentViewBottomConstraint.constant)
            print("y:", self.addCommentView.frame.origin.y)
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            print("new y:", self.addCommentView.frame.origin.y)
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
           let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            self.addCommentViewBottomConstraint.constant = 0
            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16), animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    @IBAction func shareComment(_ sender: UIButton) {
        guard let post = post, let postIndex = postIndex else {return}
        if let comment = commentTextField.text, !comment.isEmpty {
            CommentService.shared.addComment(postId: post.id, text: comment) { success, comment, errorMessage in
                DispatchQueue.main.async {
                    if success, let comment = comment {
                        self.comments.append(comment)
                        self.tableView.reloadData()
                        self.commentTextField.text = ""
                        self.delegate?.commentsViewController(self, commentAddedAt: postIndex)
                        self.commentTextField.resignFirstResponder()
                    } else {
                        //şimdilik boş.
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        cell.selectionStyle = .none
        cell.configure(with: comments[indexPath.row])
        return cell
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if !commentTextField.text!.isEmpty {
            shareCommentButton.isUserInteractionEnabled = true
            shareCommentButton.tintColor = .systemBlue
        } else {
            shareCommentButton.isUserInteractionEnabled = false
            shareCommentButton.tintColor = .systemGray
        }
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        imageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "placeholder")
        )
    }
    
}
