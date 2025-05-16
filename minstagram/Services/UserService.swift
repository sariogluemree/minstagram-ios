//
//  UserService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 18.03.2025.
//

import Foundation

class UserService {
    
    static let shared = UserService()

    private let profileURL = APIEndpoints.forUser.profile.url
    private let updateURL = APIEndpoints.forUser.update.url
    private let deleteURL = APIEndpoints.forUser.delete.url
    private let alluserURL = APIEndpoints.forUser.all.url

    // MARK: - Get User Profile
    func getProfile<T: Decodable>(username: String, type: String, model: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: "\(profileURL)/\(username)?type=\(type)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz sunucu yanıtı"])))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "Sunucu hatası: \(httpResponse.statusCode)."
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(T.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get All Users
    func getAllUsers(completion: @escaping (Result<[PostUser], Error>) -> Void) {
        guard let url = URL(string: alluserURL) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let request = URLRequest(url: url)
        
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
                let users = try JSONDecoder().decode([PostUser].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    // MARK: - Update User Profile
    func updateProfile(user: UserDetail, completion: @escaping (Result<UserDetail, Error>) -> Void) {
        guard let url = URL(string: updateURL) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        print(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let tokenData = KeychainHelper.shared.read(service: "com.minstagram.auth", account: "userToken"),
           let token = String(data: tokenData, encoding: .utf8), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = ["name": user.name,
                                   "username": user.username,
                                   "bio": user.bio,
                                   "profilePhoto": user.profilePhoto]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted])
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON to be sent:\n\(jsonString)")
            }
        } catch {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON oluşturulurken hata meydana geldi"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz sunucu yanıtı"])))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "Sunucu hatası: \(httpResponse.statusCode)."
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let str = String(data: data, encoding: .utf8) {
                print("⛳️ JSON STRING:\n\(str)")
            } else {
                print("🚫 JSON could not be decoded into string")
            }
            print("Data length: \(data.count) bytes")


            do {
                let updatedUser = try JSONDecoder().decode(UserDetail.self, from: data)
                completion(.success(updatedUser))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Delete User
    func deleteUser(token: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: deleteURL) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz sunucu yanıtı"])))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "Sunucu hatası: \(httpResponse.statusCode)."
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let successMessage = try JSONDecoder().decode(String.self, from: data)
                completion(.success(successMessage))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
}

