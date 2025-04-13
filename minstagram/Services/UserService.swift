//
//  UserService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 18.03.2025.
//

import Foundation

class UserService {

    private let profileURL = APIEndpoints.forUser.profile.url
    private let updateURL = APIEndpoints.forUser.update.url
    private let deleteURL = APIEndpoints.forUser.delete.url

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

    // MARK: - Update User Profile
    func updateProfile(token: String, name: String?, bio: String?, profilePhoto: String?, completion: @escaping (Result<UserDetail, Error>) -> Void) {
        guard let url = URL(string: updateURL) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let bio = bio { body["bio"] = bio }
        if let profilePhoto = profilePhoto { body["profilePhoto"] = profilePhoto }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
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

