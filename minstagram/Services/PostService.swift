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
    private var tokenData = KeychainHelper.shared.read(service: "minstagram", account: "token")
    
    private init() {
        if tokenData != nil {
            
        }
        if let token = String(data: tokenData!, encoding: .utf8), !token.isEmpty {
            
        }
    }
    
    func createPost(token: String, imageUrl: String, caption: String?, tags: [String]?, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let url = URL(string: postBaseUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "imageUrl": imageUrl,
            "caption": caption ?? "",
            "tags": tags ?? []
        ]
        
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
        guard let url = URL(string: postBaseUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
        guard let url = URL(string: "\(URLSession.shared)/\(id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
    
    func deletePost(token: String, byId id: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(postBaseUrl)/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
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
    
    func updatePost(token: String, byId id: String, caption: String, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let url = URL(string: "\(postBaseUrl)/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
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
