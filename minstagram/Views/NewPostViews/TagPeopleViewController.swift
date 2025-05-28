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
    @IBOutlet weak var tagsTitleLabel: UILabel!
    
    var searchBar: UISearchBar!
    var searchResultsTableView: UITableView!
    var postImg = UIImage()
    
    var followerList: [PostUser] = [] //Sayfa yüklendiğinde activeUser'ın tüm takipçilerini çeker. Bunu taglemek istenirse yapıcaz. Bu nedenle optional olacak.
    var filteredFollowers: [PostUser] = [] //Bu da optional olacak. followerList varsa var olacak.
    var isSearching = false //Bu da arama
    var tagView: UIView?
    var tagViewsDict: [String: UIView] = [:]  // tag balonlarını tutuyor
    var tagList: [Tag] = []
    
    let userService = UserService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupNewPostImageView()
        setupHintLabel()
        fetchFollowers()
        setupSearchBar()
        setupTableViews()
        
    }
    
    private func setupNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = "Tag People"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        navigationItem.titleView = titleLabel
    }
    
    private func setupNewPostImageView() {
        newPostImgView.image = postImg
        newPostImgView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        newPostImgView.addGestureRecognizer(tapGesture)
    }
    
    private func setupHintLabel() {
        hintLabel = UILabel()
        hintLabel.isHidden = tagList.isEmpty ? false : true
        hintLabel.text = "Tap photo to tag people"
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)
        
        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: newPostImgView.bottomAnchor, constant: 100)
        ])
    }
    
    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.frame = CGRect(x: 0, y: 44, width: self.view.frame.width, height: 44)
        searchBar.isHidden = true
        view.addSubview(searchBar)
    }
    
    private func setupTableViews() {
        tagsTableView.delegate = self
        tagsTableView.dataSource = self
        
        searchResultsTableView = UITableView(frame: CGRect(x: 0, y: 88, width: self.view.frame.width, height: 416))
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.isHidden = true
        view.addSubview(searchResultsTableView)
    }
    
    private func fetchFollowers() {
        guard let activeUser = UserManager.shared.activeUser else { return }
        
        FollowService.shared.getFollowers(userId: activeUser.username) { [weak self] (followers, success, message) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    self.followerList = followers ?? []
                    if !self.tagList.isEmpty {
                        for tag in self.tagList {
                            let point = CGPoint(x: tag.position.x, y: tag.position.y)
                            self.addTagBalloon(at: point, username: tag.taggedUser.username)
                            for i in 0..<self.followerList.count {
                                if self.followerList[i].username == tag.taggedUser.username {
                                    self.followerList.remove(at: i)
                                    break
                                }
                            }
                            self.tagViewsDict[tag.taggedUser.username] = self.tagView
                        }
                    }

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
        let tagBalloon = TagBalloon(username: username, position: point, in: newPostImgView)
        newPostImgView.addSubview(tagBalloon)
        tagView = tagBalloon
    }
    
    func updateTagView(with username: String) {
        (tagView as? TagBalloon)?.updateUsername(username, in: newPostImgView)
    }

    
    @IBAction func backBtnPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneBtnPressed(_ sender: UIBarButtonItem) {
        if let viewControllers = navigationController?.viewControllers {
            for controller in viewControllers {
                if let postOptionsVC = controller as? PostOptionsViewController {
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
                //.map { $0.username }  // Sonuçta sadece `username` değerlerini almak için `map` kullanıyoruz.
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
        tagsTitleLabel.isHidden = tagList.isEmpty
        hintLabel.isHidden = !tagList.isEmpty
        return tagList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchResultsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")

            cell.textLabel?.text = filteredFollowers[indexPath.row].username
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
            let taggedUser = tagList[indexPath.row].taggedUser
            let tagRow = RowView(icon: UIImage(systemName: "person.circle.fill"), title: taggedUser.username, rowType: RowType.taggedUser) {
                let removedTag = self.tagList[indexPath.row]
                self.tagList.remove(at: indexPath.row)
                if let tagView = self.tagViewsDict[removedTag.taggedUser.username] {
                    tagView.removeFromSuperview()
                    self.tagViewsDict.removeValue(forKey: removedTag.taggedUser.username)
                }
                self.tagsTableView.reloadData()
                self.followerList.append(taggedUser)
            }
            for view in cell.contentView.subviews {
                view.removeFromSuperview()
            }
            cell.contentView.addSubview(tagRow)
            NSLayoutConstraint.activate([
                tagRow.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                tagRow.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                tagRow.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchResultsTableView {
            let username = filteredFollowers[indexPath.row].username
            updateTagView(with: "@\(username)")

            searchBar.text = ""
            searchResultsTableView.isHidden = true
            searchBar.isHidden = true
            searchBar.resignFirstResponder()
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            newPostImgView.isHidden = false
            
            userService.getProfile(username: username, type: "post", model: PostUser.self) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let taggedUser):
                        let x = self.tagView!.frame.origin.x
                        let y = self.tagView!.frame.origin.y
                        let position = Position(x: x, y: y)
                        let tag = Tag(taggedUser: taggedUser, position: position)
                        self.tagList.append(tag)
                        self.tagViewsDict[username] = self.tagView
                        self.tagsTableView.reloadData()
                        for i in 0..<self.followerList.count {
                            if self.followerList[i].username == username {
                                self.followerList.remove(at: i)
                                break
                            }
                        }
                    case .failure(let error):
                        self.showAlert(message: error.localizedDescription)
                    }
                }
            }
        } else {
            print("a")
            //ya hiçbir şey yapma ya da taglenen kişinin profiline git.
        }
    }
    
}
