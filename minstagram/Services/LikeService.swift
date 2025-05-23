//
//  LikeService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 18.04.2025.
//

import Foundation

class LikeService {
    
    static let shared = LikeService()
    private let likeURL = APIEndpoints.forLike.like.url
    private let unlikeURL = APIEndpoints.forLike.unlike.url
    private let getLikesURL = APIEndpoints.forLike.getAll.url
    
    private var token: String?
    
    private init() {
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            self.token = token
        } else {
            //kullanıcıyı giriş yapmaya yönlendir.
        }
    }
    
    // 1. Like eklemek için POST isteği
    func likePost(postId: String, completion: @escaping (Result<Like, Error>) -> Void) {
        guard let url = URL(string: likeURL) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])))
            return
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
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            print(String(data: data, encoding: .utf8) ?? "no data")
            
            do {
                let like = try JSONDecoder().decode(Like.self, from: data)
                completion(.success(like))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // 2. Like silmek için DELETE isteği
    func unlikePost(postId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: unlikeURL) else {
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
    
    // 3. Belirli bir post için tüm like'ları almak için GET isteği
    func getLikesForPost(postId: String, completion: @escaping (Result<[Like], Error>) -> Void) {
        let url = URL(string: getLikesURL)!
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
                let likes = try JSONDecoder().decode([Like].self, from: data)
                completion(.success(likes))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
