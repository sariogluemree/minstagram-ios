//
//  UserSearchViewController.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 22.04.2025.
//

import UIKit

class UserSearchViewController: UIViewController {
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    
    private var users: [PostUser] = []
    private var filteredUsers: [PostUser] = []
    
    var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupSearchBar()
        setupTableView()
        fetchUsers()
    }
    
    private func setupNavigationBar() {
        let backBtn = UIBarButtonItem(image: UIImage(systemName: "arrow.backward"), style: .plain, target: self, action: #selector(back))
        backBtn.tintColor = .black
        navigationItem.leftBarButtonItem = backBtn
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Kullanıcı ara"
        navigationItem.titleView = searchBar
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self, forCellReuseIdentifier: "UserCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchUsers() {
        UserService.shared.getAllUsers { [weak self] result in
            switch result {
                case .success(let users):
                DispatchQueue.main.async {
                    self?.users = users
                    self?.filteredUsers = users
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
}

extension UserSearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        let user = filteredUsers[indexPath.row]
        cell.configure(with: user)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let user = filteredUsers[indexPath.row]
        UserService.shared.getProfile(username: user.username, type: "public", model: UserDetail.self) { result in
            switch result {
            case .success(let userDetail):
                DispatchQueue.main.async {
                    let sb = UIStoryboard(name: "Profile", bundle: nil)
                    let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    vc.user = userDetail
                    vc.backBtn.isHidden = false
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension UserSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { $0.username.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
}
