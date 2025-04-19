//
//  PostService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 27.03.2025.
//

import Foundation

struct PostResponse<T: Codable>: Codable {
    let error: String?
    let data: T?
}

class PostService {
    
    static let shared = PostService()
    private let postBaseUrl = APIEndpoints.forPost.all.url
    private let feedURL = APIEndpoints.forPost.feed.url
    private let getPostURL = APIEndpoints.forPost.post.url
    private var token: String?
    
    private init() {
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            self.token = token
        } else {
            //kullanıcıyı giriş yapmaya yönlendir.
        }
    }
    
    func createPost(imageUrl: String, caption: String?, tags: [Tag]?, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let url = URL(string: postBaseUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "imageUrl": imageUrl,
            "caption": caption ?? "",
        ]
        
        if let tags = tags {
            let tagArray = tags.map { tag -> [String: Any] in
                return [
                    "taggedUser": tag.taggedUser.id,
                    "position": [
                        "x": tag.position.x,
                        "y": tag.position.y
                    ]
                ]
            }
            body["tags"] = tagArray
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            do {
                let post = try JSONDecoder().decode(Post.self, from: data)
                completion(.success(post))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchAllPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        guard let url = URL(string: feedURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            do {
                let posts = try JSONDecoder().decode([Post].self, from: data)
                completion(.success(posts))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchPost(byId id: String, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let url = URL(string: "\(getPostURL)/\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue( "application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            do {
                let post = try JSONDecoder().decode(Post.self, from: data)
                completion(.success(post))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func deletePost(byId id: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(postBaseUrl)/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(PostResponse<String>.self, from: data)
                if let error = response.error {
                    completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: error])))
                } else {
                    completion(.success("Post başarıyla silindi."))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func updatePost(byId id: String, caption: String, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let url = URL(string: "\(postBaseUrl)/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        
        let body = ["caption": caption]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            do {
                let post = try JSONDecoder().decode(Post.self, from: data)
                completion(.success(post))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
}
