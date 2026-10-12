//
//  Endpoint.swift
//  minstagram
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Bir API isteğini tarif eden, sadece veri tutan tip.
/// Networking kodu içermez; isteği `NetworkManager` oluşturur ve gönderir.
protocol Endpoint {
    /// `APIConfig.baseURL`'e göre göreli yol. Örn: `"posts/feed"`.
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    /// JSON olarak gönderilecek gövde. Method'dan bağımsızdır (backend bazı `DELETE` isteklerinde body bekliyor).
    var body: (any Encodable)? { get }
    /// `true` ise `Authorization: Bearer <token>` eklenir; token yoksa istek gönderilmez.
    var requiresAuth: Bool { get }
}

extension Endpoint {
    var queryItems: [URLQueryItem]? { nil }
    var body: (any Encodable)? { nil }
    var requiresAuth: Bool { true }
}
