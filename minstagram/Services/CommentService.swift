//
//  CommentService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 16.04.2025.
//

import Foundation

class CommentService {
    static let shared = CommentService()
    private let createURL = APIEndpoints.forComment.create.url
    private let getCommentsURL = APIEndpoints.forComment.getAll.url
    private let deleteURL = APIEndpoints.forComment.delete.url
    private var token: String?
    
    private init() {
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            self.token = token
        } else {
            //kullanıcıyı giriş yapmaya yönlendir.
        }
    }

    // MARK: - Yorum Ekle
    func addComment(postId: String, text: String, completion: @escaping (Bool, Comment?, String?) -> Void) {
        guard let url = URL(string: createURL) else {
            completion(false, nil, "Geçersiz URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "postId": postId,
            "text": text
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(false, nil, "JSON oluşturulamadı")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, nil, error.localizedDescription)
                return
            }
            guard let data = data else {
                completion(false, nil, "Veri alınamadı")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    do {
                        let comment = try JSONDecoder().decode(Comment.self, from: data)
                        completion(true, comment, nil)
                    } catch {
                        completion(false, nil, error.localizedDescription)
                    }
                } else {
                    completion(false, nil, "İşlem başarısız. Status: \(httpResponse.statusCode)")
                }
            } else {
                completion(false, nil, "Geçersiz yanıt.")
            }
        }.resume()
    }

    // MARK: - Yorumları Getir
    func getComments(forPostId postId: String, completion: @escaping ([Comment]?, String?) -> Void) {
        guard let url = URL(string: "\(getCommentsURL)/\(postId)") else {
            completion(nil, "Geçersiz URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }

            guard let data = data else {
                completion(nil, "Veri alınamadı")
                return
            }

            do {
                let comments = try JSONDecoder().decode([Comment].self, from: data)
                completion(comments, nil)
            } catch {
                completion(nil, "JSON çözümleme hatası: \(error.localizedDescription)")
            }
        }.resume()
    }

    // MARK: - Yorumu Sil
    func deleteComment(commentId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(deleteURL)/\(commentId)") else {
            completion(false, "Geçersiz URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true, nil)
            } else {
                completion(false, "Yorum silinemedi.")
            }
        }.resume()
    }
}
