//
//  SavedPostsViewController.swift
//  minstagram
//

import UIKit

class SavedPostsViewController: UIViewController {

    private var posts: [Post] = []
    private var collectionView: UICollectionView!

    private let emptyStateLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No saved posts yet"
        lbl.textColor = .secondaryLabel
        lbl.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        lbl.textAlignment = .center
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSavedPosts()
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
        titleLabel.text = "Saved"
        titleLabel.font = UIFont(name: "Helvetica Neue", size: 22)
        titleLabel.sizeToFit()
        let titleItem = UIBarButtonItem(customView: titleLabel)
        navigationItem.leftBarButtonItems = [backBtn, titleItem]
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PostCollectionCell.self, forCellWithReuseIdentifier: "PostCollectionCell")

        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func fetchSavedPosts() {
        guard let activeUserId = UserManager.shared.activeUser?.id else { return }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let savedPosts = try await NetworkManager.shared.request(
                    SavedPostEndpoint.getAll(userId: activeUserId),
                    as: [Post].self
                )
                self.posts = savedPosts
                self.emptyStateLabel.isHidden = !savedPosts.isEmpty
                self.collectionView.reloadData()
            } catch {
                self.showError(error)
            }
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension SavedPostsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCollectionCell", for: indexPath) as? PostCollectionCell,
              posts.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }
        cell.configure(with: posts[indexPath.item].imageUrl)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = 3
        let padding: CGFloat = 4
        let totalSpacing = (itemsPerRow - 1) * padding
        let availableWidth = collectionView.bounds.width - totalSpacing
        let width = availableWidth / itemsPerRow
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "FeedViewController") as? FeedViewController else { return }
        vc.mode = .userPosts
        vc.postIndex = indexPath.row
        vc.posts = posts
        navigationController?.pushViewController(vc, animated: true)
    }
}
