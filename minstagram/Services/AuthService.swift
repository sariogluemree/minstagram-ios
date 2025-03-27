//
//  AuthService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 2.03.2025.
//


import Foundation

struct LoginResponse: Codable {
    let token: String?
    let user: User?
}

struct RegisterResponse: Codable {
    let newUser: User?
    let registerMessage: String?
}

class AuthService {
    
    private let registerURL = APIEndpoints.forAuth.register.url
    private let loginURL = APIEndpoints.forAuth.login.url
    
    func register(email: String, username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let body = ["email": email, "username": username, "password": password]
        performRegister(urlString: registerURL, body: body, completion: completion)
    }

    func login(user: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let body = ["emailOrUsername": user, "password": password]
        performLogin(urlString: loginURL, body: body, completion: completion)
    }
    
    private func performRegister(urlString: String, body: [String: String], completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false, "Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(false, "JSON oluşturulurken hata meydana geldi")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let data = data else {
                completion(false, "Veri alınamadı")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    do {
                        let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
                        if let registeredUser = registerResponse.newUser, let message = registerResponse.registerMessage {
                            UserManager.shared.register(user: registeredUser)
                            completion(true, message)
                        }
                    } catch {
                        completion(false, "JSON parsing hatası")
                    }
                } else {
                    let errorMessage = handleMessage(data: data) ?? "İşlem başarısız. Status: \(httpResponse.statusCode)"
                    completion(false, errorMessage)
                }
            } else {
                completion(false, "Geçersiz yanıt")
            }
        }
        task.resume()
    }
    
    private func performLogin(urlString: String, body: [String: String], completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false, "Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(false, "JSON oluşturulurken hata meydana geldi")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let data = data else {
                completion(false, "Veri alınamadı")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    do {
                        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                        if let token = loginResponse.token, let user = loginResponse.user {
                            if let tokenData = token.data(using: .utf8) {
                                UserManager.shared.login(tokenData: tokenData, user: user)
                                completion(true, nil)
                            }
                        }
                    } catch {
                        completion(false, "JSON parsing hatası")
                    }
                } else {
                    let errorMessage = handleMessage(data: data) ?? "İşlem başarısız. Status: \(httpResponse.statusCode)"
                    completion(false, errorMessage)
                }
            } else {
                completion(false, "Geçersiz yanıt")
            }
        }
        task.resume()
    }

}
