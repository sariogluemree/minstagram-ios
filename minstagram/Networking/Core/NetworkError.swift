//
//  NetworkError.swift
//  minstagram
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case encoding(Error)
    /// URLSession seviyesinde hata (internet yok, timeout, sunucuya ulaşılamadı...).
    case transport(Error)
    case invalidResponse
    /// 401 veya auth gerektiren istekte token yok. Oturum sonlandırılır.
    case unauthorized(message: String?)
    /// 2xx dışı yanıt. `message` backend'in döndüğü hata metnidir.
    case server(statusCode: Int, message: String?)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .encoding:
            return "İstek oluşturulamadı"
        case .transport(let error):
            guard let urlError = error as? URLError else { return error.localizedDescription }
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "İnternet bağlantısı yok"
            case .timedOut:
                return "İstek zaman aşımına uğradı"
            case .cannotConnectToHost, .cannotFindHost:
                return "Sunucuya bağlanılamadı"
            default:
                return urlError.localizedDescription
            }
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .unauthorized:
            return "Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın."
        case .server(let statusCode, let message):
            return message ?? "İşlem başarısız. (Kod: \(statusCode))"
        case .decoding:
            return "Sunucu yanıtı okunamadı"
        }
    }

    var isUnauthorized: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    var isCancelled: Bool {
        if case .transport(let error) = self, (error as? URLError)?.code == .cancelled { return true }
        return false
    }
}

/// Backend hata gövdeleri tutarsız: `{"message": ...}`, `{"error": "..."}`, `{"message": ..., "error": {...}}` veya düz metin.
struct APIErrorBody: Decodable {
    let message: String?
    let error: String?

    private enum CodingKeys: String, CodingKey { case message, error }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // `error` bazen obje olduğu için tip uyuşmazlığında hata fırlatmak yerine nil kabul edilir.
        message = try? container.decode(String.self, forKey: .message)
        error = try? container.decode(String.self, forKey: .error)
    }

    static func message(from data: Data) -> String? {
        if let body = try? JSONDecoder().decode(APIErrorBody.self, from: data),
           let message = body.message ?? body.error,
           !message.isEmpty {
            return message
        }
        // `res.send('Post not found')` gibi düz metin yanıtlar. JSON/HTML gövdeler mesaj olarak gösterilmez.
        if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty, !text.hasPrefix("{"), !text.hasPrefix("["), !text.hasPrefix("<") {
            return text
        }
        return nil
    }
}
