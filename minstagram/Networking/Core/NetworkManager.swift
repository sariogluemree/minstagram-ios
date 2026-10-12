//
//  NetworkManager.swift
//  minstagram
//

import Foundation

extension Notification.Name {
    /// Token geçersiz/süresi dolmuş (401). SceneDelegate dinler: logout + login ekranı.
    static let sessionExpired = Notification.Name("com.minstagram.sessionExpired")
}

protocol NetworkManaging {
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
    /// Yanıt gövdesi kullanılmayan istekler.
    func request(_ endpoint: Endpoint) async throws
    func upload<T: Decodable>(_ endpoint: Endpoint, form: MultipartFormData, as type: T.Type) async throws -> T
}

final class NetworkManager: NetworkManaging {

    static let shared = NetworkManager()

    private let session: URLSession
    private let baseURL: URL
    private let tokenProvider: TokenProviding
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let onUnauthorized: () -> Void

    init(session: URLSession = NetworkManager.makeDefaultSession(),
         baseURL: URL = APIConfig.baseURL,
         tokenProvider: TokenProviding = KeychainTokenProvider(),
         decoder: JSONDecoder = .api,
         encoder: JSONEncoder = .api,
         onUnauthorized: @escaping () -> Void = NetworkManager.postSessionExpired) {
        self.session = session
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.decoder = decoder
        self.encoder = encoder
        self.onUnauthorized = onUnauthorized
    }

    // MARK: - Public API

    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try makeRequest(for: endpoint)
        let data = try await perform(request, requiresAuth: endpoint.requiresAuth)
        return try decode(T.self, from: data, for: request)
    }

    func request(_ endpoint: Endpoint) async throws {
        let request = try makeRequest(for: endpoint)
        _ = try await perform(request, requiresAuth: endpoint.requiresAuth)
    }

    func upload<T: Decodable>(_ endpoint: Endpoint, form: MultipartFormData, as type: T.Type) async throws -> T {
        var request = try makeRequest(for: endpoint, includeBody: false)
        request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = form.encoded()
        let data = try await perform(request, requiresAuth: endpoint.requiresAuth)
        return try decode(T.self, from: data, for: request)
    }

    // MARK: - Request building

    func makeRequest(for endpoint: Endpoint, includeBody: Bool = true) throws -> URLRequest {
        let url = baseURL.appending(path: endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let finalURL = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth {
            guard let token = tokenProvider.token else {
                handleUnauthorized()
                throw NetworkError.unauthorized(message: nil)
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if includeBody, let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encoding(error)
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    // MARK: - Execution

    private func perform(_ request: URLRequest, requiresAuth: Bool) async throws -> Data {
        NetworkLogger.log(request: request)
        let start = Date()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            NetworkLogger.log(error: error, for: request)
            throw NetworkError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        NetworkLogger.log(response: http, data: data, for: request, duration: Date().timeIntervalSince(start))

        switch http.statusCode {
        case 200..<300:
            return data
        case 401 where requiresAuth:
            handleUnauthorized()
            throw NetworkError.unauthorized(message: APIErrorBody.message(from: data))
        default:
            throw NetworkError.server(statusCode: http.statusCode, message: APIErrorBody.message(from: data))
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data, for request: URLRequest) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            NetworkLogger.log(decodingError: error, data: data, for: request)
            throw NetworkError.decoding(error)
        }
    }

    private func handleUnauthorized() {
        onUnauthorized()
    }

    // MARK: - Defaults

    static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.requestTimeout
        return URLSession(configuration: configuration)
    }

    static func postSessionExpired() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }
}
