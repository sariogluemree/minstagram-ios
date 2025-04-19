//
//  SavedPostService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 19.04.2025.
//

import Foundation

class SavedPostService {
    static let shared = SavedPostService()
    private let saveUrl = APIEndpoints.forSavedPost.save.url
    private let unsaveUrl = APIEndpoints.forSavedPost.unsave.url
    private let getSavedPostsUrl = APIEndpoints.forSavedPost.getAll.url
    private var token: String?
    
    private init() {
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            self.token = token
        } else {
            //kullanıcıyı giriş yapmaya yönlendir.
        }
    }
    
    func savePost(postId: String, completion: @escaping (Result<SavedPost, Error>) -> Void) {
        guard let url = URL(string: saveUrl) else {
            return completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = ["postId": postId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let data = data else {
                return completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
            }
            
            do {
                let savedPost = try JSONDecoder().decode(SavedPost.self, from: data)
                completion(.success(savedPost))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func unsavePost(postId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: unsaveUrl) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = ["postId": postId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let responseMessage = try JSONDecoder().decode([String: String].self, from: data)
                if let message = responseMessage["message"] {
                    completion(.success(message))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No message received"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func getSavedPosts(userId: String, completion: @escaping (Result<[SavedPost], Error>) -> Void) {
        let urlString = "\(getSavedPostsUrl)/\(userId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let savedPosts = try JSONDecoder().decode([SavedPost].self, from: data)
                completion(.success(savedPosts))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    
}
