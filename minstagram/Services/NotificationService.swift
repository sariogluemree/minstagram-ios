//
//  NotificationService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 21.05.2025.
//

import Foundation

enum NotificationType: String, Codable {
    case follow
    case like
    case comment
    case tag
}

struct MarkSeenResponse: Decodable {
    let success: Bool
}

struct AppNotification: Codable {
    let id: String
    let type: NotificationType
    let sender: PostUser
    let postId: String?
    let comment: Comment?
    var seen: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case sender = "senderId"
        case postId
        case comment = "commentId"
        case seen
        case createdAt
    }
}

class NotificationService {
    
    static let shared = NotificationService()
    private let getUrl = APIEndpoints.forNotification.get.url
    private let markSeenUrl = APIEndpoints.forNotification.seen.url
    private var token: String?
    
    private init() {
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            self.token = token
        } else {
            //kullanıcıyı giriş yapmaya yönlendir.
        }
    }

    func fetchNotifications(completion: @escaping (Result<[AppNotification], Error>) -> Void) {
        guard let url = URL(string: getUrl) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])))
            return
        }
        print("url:", url)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date string does not match format expected by formatter.")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "Network", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            do {
                let notifications = try decoder.decode([AppNotification].self, from: data)
                completion(.success(notifications))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func markAsSeen(notificationId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(markSeenUrl)/\(notificationId)") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let decoded = try? JSONDecoder().decode(MarkSeenResponse.self, from: data) else {
                completion(.failure(NSError(domain: "InvalidResponse", code: -2)))
                return
            }
            completion(.success(decoded.success))
        }.resume()
    }
    
}
