//
//  FollowService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 22.03.2025.
//

import Foundation

class FollowService {
    
    static let shared = FollowService()
    
    private let followURL = APIEndpoints.forFollow.follow.url
    private let unfollowURL = APIEndpoints.forFollow.unfollow.url
    private let followingURL = APIEndpoints.forFollow.following.url
    private let followersURL = APIEndpoints.forFollow.followers.url
    private let isFollowingURL = APIEndpoints.forFollow.isFollowing.url
    
    private var token: String?
    
    private init() {
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            self.token = token
        } else {
            //kullanıcıyı giriş yapmaya yönlendir.
        }
    }
    
    /// Kullanıcıyı takip et
    func followUser(followingId: String, completion: @escaping (Bool, String?) -> Void) {
        let body: [String: Any] = ["followingId": followingId]
        performRequest(urlString: followURL, httpMethod: "POST", body: body, completion: completion)
    }
    
    /// Kullanıcıyı takipten çık
    func unfollowUser(followingId: String, completion: @escaping (Bool, String?) -> Void) {
        let body: [String: Any] = ["followingId": followingId]
        performRequest(urlString: unfollowURL, httpMethod: "POST", body: body, completion: completion)
    }
        
    /// Kullanıcının takip ettiği kişileri getir
    func getFollowing(userId: String, completion: @escaping ([PostUser]?, Bool, String?) -> Void) {
        let url = "\(followingURL)/\(userId)"
        performGetRequest(urlString: url, completion: completion)
    }
    
    /// Kullanıcının takipçilerini getir
    func getFollowers(userId: String, completion: @escaping ([PostUser]?, Bool, String?) -> Void) {
        let url = "\(followersURL)/\(userId)"
        performGetRequest(urlString: url, completion: completion)
    }
    

    func isFollowing(followingId: String, completion: @escaping (Bool?, Error?) -> Void) {
        guard let url = URL(string: "\(isFollowingURL)?followingId=\(followingId)") else {
            completion(nil, NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let data = data else {
                completion(nil, NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let isFollowing = jsonResponse?["isFollowing"] as? Bool {
                    completion(isFollowing, nil)
                } else {
                    completion(nil, NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }

    
    /// HTTP POST veya DELETE işlemlerini yapar
    private func performRequest(urlString: String, httpMethod: String, body: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false, "Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(false, "JSON oluşturulurken hata meydana geldi")
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    completion(true, nil)
                } else {
                    completion(false, "İşlem başarısız. Status: \(httpResponse.statusCode)")
                }
            } else {
                completion(false, "Geçersiz yanıt.")
            }
            
        }.resume()
    }
    
    /// HTTP GET işlemleri için genel fonksiyon
    private func performGetRequest(urlString: String, completion: @escaping ([PostUser]?, Bool, String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, false, "Geçersiz URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, false, error.localizedDescription)
                return
            }
            
            guard let data = data else {
                completion(nil, false, "Veri alınamadı.")
                return
            }
            
            do {
                let users = try JSONDecoder().decode([PostUser].self, from: data)
                completion(users, true, nil)
            } catch {
                completion(nil, false, "JSON parsing hatası")
            }
        }.resume()
    }
}
