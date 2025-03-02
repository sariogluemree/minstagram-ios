//
//  EmailService.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 2.03.2025.
//

import Foundation

class EmailService {

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidCode(_ code: String) -> Bool {
        return code.count == 6 && code.allSatisfy { $0.isNumber }
    }
    
    private let sendEmailURL = APIEndpoints.forEmail.send.url
    private let verifyEmailURL = APIEndpoints.forEmail.verify.url
    
    func sendVerificationCode(to email: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: sendEmailURL) else {
            completion(false, "Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(false, "Beklenmeyen bir hata meydana geldi")
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
                    let sentMessage = handleMessage(data: data) ?? "Email gönderildi"
                    completion(true, sentMessage)
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
    
    func verifyEmail(email: String, code: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: verifyEmailURL) else {
            completion(false, "Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "code": code]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(false, "Beklenmeyen bir hata meydana geldi")
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
                    let verifyMessage = handleMessage(data: data) ?? "Email doğrulama başarılı"
                    completion(true, verifyMessage)
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
