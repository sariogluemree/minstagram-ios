//
//  FollowListViewController.swift
//  minstagram
//

import UIKit

enum FollowListMode: Int {
    case followers = 0
    case following = 1
}

protocol FollowListViewControllerDelegate: AnyObject {
    func didUpdateFollowCounts(followersCount: Int, followingCount: Int)
}

class FollowListViewController: UIViewController {

    private var user: UserDetail
    private var currentMode: FollowListMode
    weak var delegate: FollowListViewControllerDelegate?

    private var followers: [PostUser] = []
    private var following: [PostUser] = []
    private var filteredUsers: [PostUser] = []

    private var isFollowersLoaded = false
    private var isFollowingLoaded = false

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Followers", "Following"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.rowHeight = 60
        tv.separatorStyle = .none
        tv.keyboardDismissMode = .onDrag
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyStateLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .secondaryLabel
        lbl.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        lbl.textAlignment = .center
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let refreshControl = UIRefreshControl()

    private var isOwnProfile: Bool {
        user.id == UserManager.shared.activeUser?.id
    }

    init(user: UserDetail, initialMode: FollowListMode) {
        self.user = user
        self.currentMode = initialMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        updateSegmentTitles()
        segmentedControl.selectedSegmentIndex = currentMode.rawValue
        fetchBothLists()
    }

    private func setupNavigationBar() {
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "arrow.backward"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = .label
        navigationItem.leftBarButtonItem = backBtn

        let titleLabel = UILabel()
        titleLabel.text = user.username
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 20)
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
    }

    private func setupUI() {
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        searchBar.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserCell.self, forCellReuseIdentifier: "UserCell")
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(segmentedControl)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            searchBar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 4),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -20)
        ])
    }

    private func updateSegmentTitles() {
        segmentedControl.setTitle("\(user.followersCount) Followers", forSegmentAt: FollowListMode.followers.rawValue)
        segmentedControl.setTitle("\(user.followingCount) Following", forSegmentAt: FollowListMode.following.rawValue)
    }

    private func fetchBothLists() {
        let username = user.username
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                async let fetchedFollowers = NetworkManager.shared.request(
                    FollowEndpoint.followers(username: username),
                    as: [PostUser].self
                )
                async let fetchedFollowing = NetworkManager.shared.request(
                    FollowEndpoint.following(username: username),
                    as: [PostUser].self
                )

                let (followersResult, followingResult) = try await (fetchedFollowers, fetchedFollowing)
                self.followers = followersResult
                self.following = followingResult
                self.isFollowersLoaded = true
                self.isFollowingLoaded = true

                self.user.followersCount = followersResult.count
                self.user.followingCount = followingResult.count
                self.updateSegmentTitles()
                self.notifyCountsUpdated()
                self.applyFilterAndReload()
            } catch {
                self.showError(error)
            }
            self.refreshControl.endRefreshing()
        }
    }

    private func applyFilterAndReload() {
        let activeSource = (currentMode == .followers) ? followers : following
        let query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if query.isEmpty {
            filteredUsers = activeSource
        } else {
            filteredUsers = activeSource.filter { $0.username.lowercased().contains(query) }
        }

        let isCurrentLoaded = (currentMode == .followers) ? isFollowersLoaded : isFollowingLoaded
        if isCurrentLoaded && filteredUsers.isEmpty {
            if !query.isEmpty {
                emptyStateLabel.text = "No users found"
            } else {
                emptyStateLabel.text = (currentMode == .followers) ? "No followers yet" : "Not following anyone yet"
            }
            emptyStateLabel.isHidden = false
        } else {
            emptyStateLabel.isHidden = true
        }

        tableView.reloadData()
    }

    private func notifyCountsUpdated() {
        delegate?.didUpdateFollowCounts(followersCount: user.followersCount, followingCount: user.followingCount)
        if isOwnProfile, var activeUser = UserManager.shared.activeUser {
            activeUser.followersCount = user.followersCount
            activeUser.followingCount = user.followingCount
            UserManager.shared.updateActiveUser(user: activeUser)
        }
    }

    private func confirmRemoveFollower(_ targetUser: PostUser) {
        let alert = UIAlertController(
            title: "Remove Follower?",
            message: "We won't tell @\(targetUser.username) they were removed from your followers.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.performRemoveFollower(targetUser)
        })
        present(alert, animated: true)
    }

    private func performRemoveFollower(_ targetUser: PostUser) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                try await NetworkManager.shared.request(FollowEndpoint.removeFollower(userId: targetUser.id))
                self.followers.removeAll { $0.id == targetUser.id }
                self.user.followersCount = self.followers.count
                self.updateSegmentTitles()
                self.notifyCountsUpdated()
                self.applyFilterAndReload()
            } catch {
                self.showError(error)
            }
        }
    }

    private func performUnfollow(_ targetUser: PostUser) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                try await NetworkManager.shared.request(FollowEndpoint.unfollow(userId: targetUser.id))
                self.following.removeAll { $0.id == targetUser.id }
                self.user.followingCount = self.following.count
                self.updateSegmentTitles()
                self.notifyCountsUpdated()
                self.applyFilterAndReload()
            } catch {
                self.showError(error)
            }
        }
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        guard let mode = FollowListMode(rawValue: sender.selectedSegmentIndex) else { return }
        currentMode = mode
        applyFilterAndReload()
    }

    @objc private func handleRefresh() {
        fetchBothLists()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension FollowListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell,
              filteredUsers.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        let targetUser = filteredUsers[indexPath.row]

        if isOwnProfile {
            let actionTitle = (currentMode == .followers) ? "Remove" : "Unfollow"
            cell.configure(with: targetUser, actionTitle: actionTitle) { [weak self] in
                guard let self = self else { return }
                if self.currentMode == .followers {
                    self.confirmRemoveFollower(targetUser)
                } else {
                    self.performUnfollow(targetUser)
                }
            }
        } else {
            cell.configure(with: targetUser)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard filteredUsers.indices.contains(indexPath.row) else { return }
        let selectedUser = filteredUsers[indexPath.row]

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let userDetail = try await NetworkManager.shared.request(
                    UserEndpoint.profile(username: selectedUser.username),
                    as: UserDetail.self
                )
                let sb = UIStoryboard(name: "Profile", bundle: nil)
                guard let vc = sb.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController else { return }
                vc.user = userDetail
                vc.loadViewIfNeeded()
                vc.backBtn.isHidden = false
                self.navigationController?.pushViewController(vc, animated: true)
            } catch {
                self.showError(error)
            }
        }
    }
}

extension FollowListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilterAndReload()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
