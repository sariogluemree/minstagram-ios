//
//  AddTagViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 8.03.2025.
//

import UIKit

class TagPeopleViewController: UIViewController {
    
    var hintLabel: UILabel!
    
    @IBOutlet weak var newPostImgView: UIImageView!
    @IBOutlet weak var tagsTableView: UITableView!
    
    var searchBar: UISearchBar!
    var searchResultsTableView: UITableView!
    var postImg = UIImage()
    
    var followerList: [User] = []
    var filteredFollowers: [String] = []
    var isSearching = false
    var tagView: UIView?
    var tagViewsDict: [String: UIView] = [:]  // username -> tagView eşleşmesi
    var tagList: [User] = []
    
    let userService = UserService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleLabel = UILabel()
        titleLabel.text = "Tag People"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        navigationItem.titleView = titleLabel
        
        hintLabel = UILabel()
        hintLabel.text = "Tap photo to tag people"
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: newPostImgView.bottomAnchor, constant: 100)
        ])
        
        tagsTableView.delegate = self
        tagsTableView.dataSource = self
        
        newPostImgView.image = postImg
        newPostImgView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        newPostImgView.addGestureRecognizer(tapGesture)
        
        searchResultsTableView = UITableView(frame: CGRect(x: 0, y: 150, width: self.view.frame.width, height: 200))
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        self.view.addSubview(searchResultsTableView)
        searchResultsTableView.isHidden = true

        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.frame = CGRect(x: 0, y: 44, width: self.view.frame.width, height: 44)
        self.view.addSubview(searchBar)
        searchBar.isHidden = true
        
        
        let activeUser = UserManager.shared.activeUser!
        FollowService.shared.getFollowers(userId: activeUser.username) { (followers, success, message) in
            DispatchQueue.main.async {
                if success {
                    self.followerList = followers ?? []
                } else {
                    self.showAlert(message: message ?? "Failed to load followers")
                }
            }
        }
        
    }
    
    @objc func handleImageTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: newPostImgView)
        
        hintLabel.isHidden = true
        
        if let lastTag = newPostImgView.subviews.last {
            if let tagText = lastTag.subviews.last as? UILabel {
                if tagText.text == "Who's this?" {
                    lastTag.removeFromSuperview()
                    searchBar.text = ""
                    if tagList.isEmpty {
                        hintLabel.isHidden = false
                    }
                    searchBar.isHidden = true
                    searchResultsTableView.isHidden = true
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    newPostImgView.isHidden = false
                    searchBar.resignFirstResponder()
                    return
                }
            }
        }
        
        addTagBalloon(at: touchPoint)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        searchBar.isHidden = false
        searchBar.becomeFirstResponder()
    }
    
    func addTagBalloon(at point: CGPoint, username: String = "Who's this?") {
        let padding: CGFloat = 10
        let maxWidth: CGFloat = 200 // Maksimum genişlik sınırı koyabilirsin
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = username
        label.numberOfLines = 1
        label.sizeToFit()

        let textWidth = min(label.frame.width + padding * 2, maxWidth)
        let textHeight = label.frame.height + padding
        
        let x: CGFloat = (point.x + textWidth < self.view.frame.width) ? point.x : point.x - textWidth
        tagView = UIView(frame: CGRect(x: x, y: point.y, width: textWidth, height: textHeight))
        tagView?.backgroundColor = .gray
        tagView?.layer.cornerRadius = 10
        tagView?.layer.borderWidth = 0.5
        tagView?.layer.masksToBounds = true

        label.frame = CGRect(x: padding, y: padding / 2, width: textWidth - padding * 2, height: textHeight - padding)
        tagView?.addSubview(label)
        
        self.newPostImgView.addSubview(tagView!)
    }
    
    func updateTagView(with username: String) {
        guard let tagView = tagView,
              let label = tagView.subviews.first(where: { $0 is UILabel }) as? UILabel else { return }

        let padding: CGFloat = 10
        let maxWidth: CGFloat = 200

        // Yeni metni ata
        label.text = username
        label.sizeToFit()

        // Yeni genişlik ve yükseklik hesapla
        let textWidth = min(label.frame.width + padding * 2, maxWidth)
        let textHeight = label.frame.height + padding
        
        let tagX = tagView.frame.origin.x
        let x: CGFloat = (tagX + textWidth < self.view.frame.width) ? tagX : tagX - textWidth
        
        // Animasyonlu genişlik güncelleme
        UIView.animate(withDuration: 0.3) {
            tagView.frame = CGRect(x: x, y: tagView.frame.origin.y, width: textWidth, height: textHeight)
            label.frame = CGRect(x: padding, y: padding / 2, width: textWidth - padding * 2, height: textHeight - padding)
        }

        tagViewsDict[String(username.dropFirst())] = tagView
    }

    
    @IBAction func backBtnPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneBtnPressed(_ sender: UIBarButtonItem) {
        if let viewControllers = navigationController?.viewControllers {
            for controller in viewControllers {
                if let postOptionsVC = controller as? PostOptionsViewController {
                    postOptionsVC.newPostImgView = newPostImgView
                    postOptionsVC.tagList = tagList
                    navigationController?.popToViewController(postOptionsVC, animated: true)
                    return
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
}

extension TagPeopleViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredFollowers = []
            searchResultsTableView.isHidden = true
            newPostImgView.isHidden = false
        } else {
            isSearching = true
            filteredFollowers = followerList
                .filter { $0.username.lowercased().contains(searchText.lowercased()) }
                .map { $0.username }  // Sonuçta sadece `username` değerlerini almak için `map` kullanıyoruz.
            newPostImgView.isHidden = true
            searchResultsTableView.isHidden = false
        }
        searchResultsTableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        isSearching = false
        filteredFollowers = []
        searchResultsTableView.isHidden = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return !followerList.isEmpty
    }
}

extension TagPeopleViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchResultsTableView {
            return isSearching ? filteredFollowers.count : 0
        }
        return tagList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchResultsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")

            cell.textLabel?.text = filteredFollowers[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
            let taggedUser = tagList[indexPath.row]
            userService.getProfile(username: taggedUser.username) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let user):
                        let tagRow = RowView(icon: UIImage(systemName: "person.circle.fill"), title: user.username, rowType: RowType.taggedUser) {
                            if indexPath.row < self.tagList.count {
                                let removedUser = self.tagList[indexPath.row]
                                self.tagList.remove(at: indexPath.row)
                                if let tagView = self.tagViewsDict[removedUser.username] {
                                    tagView.removeFromSuperview()
                                    self.tagViewsDict.removeValue(forKey: removedUser.username)  // Dictionary’den de çıkar
                                }
                                if self.tagList.isEmpty {
                                    self.hintLabel.isHidden = false
                                }
                                self.tagsTableView.reloadData()
                            }
                        }
                        cell.contentView.addSubview(tagRow)
                        NSLayoutConstraint.activate([
                            tagRow.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                            tagRow.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                            tagRow.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
                        ])
                    case .failure(let error):
                        self.showAlert(message: error.localizedDescription)
                    }
                }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchResultsTableView {
            let username = filteredFollowers[indexPath.row]
            updateTagView(with: "@\(username)")
            userService.getProfile(username: username) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let user):
                        self.tagList.append(user)
                        self.tagsTableView.reloadData()
                    case .failure(let error):
                        self.showAlert(message: error.localizedDescription)
                    }
                }
            }
            searchBar.text = ""
            searchResultsTableView.isHidden = true
            searchBar.isHidden = true
            searchBar.resignFirstResponder()
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            newPostImgView.isHidden = false
        } else {
            print("a")
            //ya hiçbir şey yapma ya da taglenen kişinin profiline git.
        }
    }
    
}
