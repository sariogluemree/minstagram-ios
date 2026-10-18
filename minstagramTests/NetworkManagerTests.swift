//
//  NetworkManagerTests.swift
//  minstagramTests
//

import Foundation
import Testing
@testable import minstagram

/// `MockURLProtocol` statik durum paylaştığı için seri çalışır.
@Suite(.serialized)
struct NetworkManagerTests {

    init() {
        MockURLProtocol.reset()
    }

    // MARK: - Request building

    @Test func addsBearerTokenForAuthenticatedEndpoint() throws {
        let manager = TestNetwork.makeManager(token: "abc123")
        let request = try manager.makeRequest(for: PostEndpoint.feed)

        #expect(request.url?.absoluteString == "https://test.local/api/posts/feed")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
        #expect(request.httpBody == nil)
    }

    @Test func omitsTokenForPublicEndpoint() throws {
        let manager = TestNetwork.makeManager(token: "abc123")
        let request = try manager.makeRequest(for: AuthEndpoint.login(LoginRequest(emailOrUsername: "emre", password: "123456")))

        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request.httpMethod == "POST")
    }

    @Test func encodesJSONBody() throws {
        let manager = TestNetwork.makeManager()
        let request = try manager.makeRequest(for: AuthEndpoint.login(LoginRequest(emailOrUsername: "emre", password: "123456")))

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json == ["emailOrUsername": "emre", "password": "123456"])
    }

    @Test func sendsBodyWithDeleteRequests() throws {
        let manager = TestNetwork.makeManager()
        let request = try manager.makeRequest(for: LikeEndpoint.unlike(postId: "p1"))

        #expect(request.httpMethod == "DELETE")
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json == ["postId": "p1"])
    }

    @Test func appendsQueryItems() throws {
        let manager = TestNetwork.makeManager()

        let profile = try manager.makeRequest(for: UserEndpoint.profile(username: "emre"))
        #expect(profile.url?.absoluteString == "https://test.local/api/users/profile/emre?type=public")

        let isFollowing = try manager.makeRequest(for: FollowEndpoint.isFollowing(userId: "u42"))
        #expect(isFollowing.url?.absoluteString == "https://test.local/api/follows/isFollowing?followingId=u42")
    }

    @Test func missingTokenThrowsUnauthorizedWithoutSendingRequest() async {
        let counter = CallCounter()
        let manager = TestNetwork.makeManager(token: nil, counter: counter)
        TestNetwork.respond(status: 200, json: "[]")

        do {
            _ = try await manager.request(PostEndpoint.feed, as: [Post].self)
            Issue.record("Hata bekleniyordu")
        } catch let error as NetworkError {
            #expect(error.isUnauthorized)
        } catch {
            Issue.record("Beklenmeyen hata: \(error)")
        }

        #expect(MockURLProtocol.receivedRequests.isEmpty)
        #expect(counter.count == 1)
    }

    // MARK: - Responses

    @Test func decodesSuccessfulResponse() async throws {
        let manager = TestNetwork.makeManager(token: "abc123")
        TestNetwork.respond(status: 200, json: #"{"isFollowing": true}"#)

        let response = try await manager.request(FollowEndpoint.isFollowing(userId: "u1"), as: IsFollowingResponse.self)

        #expect(response.isFollowing)
        let sent = try #require(MockURLProtocol.receivedRequests.first)
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
        #expect(sent.url?.absoluteString == "https://test.local/api/follows/isFollowing?followingId=u1")
    }

    @Test func requestWithoutResponseBodySucceedsOn2xx() async throws {
        let manager = TestNetwork.makeManager()
        TestNetwork.respond(status: 204, data: Data())

        try await manager.request(SavedPostEndpoint.save(postId: "p1"))

        #expect(MockURLProtocol.receivedRequests.count == 1)
    }

    @Test(arguments: [
        (#"{"message": "Post bulunamadı"}"#, "Post bulunamadı"),
        (#"{"error": "Geçersiz kod"}"#, "Geçersiz kod"),
        (#"{"message": "Kayıt başarısız", "error": {"code": 11000}}"#, "Kayıt başarısız"),
        ("Post not found", "Post not found"),
    ])
    func serverErrorParsesBackendMessage(body: String, expected: String) async {
        let counter = CallCounter()
        let manager = TestNetwork.makeManager(counter: counter)
        TestNetwork.respond(status: 404, json: body)

        do {
            _ = try await manager.request(PostEndpoint.detail(id: "p1"), as: Post.self)
            Issue.record("Hata bekleniyordu")
        } catch let error as NetworkError {
            guard case .server(let statusCode, let message) = error else {
                Issue.record("`.server` bekleniyordu, gelen: \(error)")
                return
            }
            #expect(statusCode == 404)
            #expect(message == expected)
            #expect(error.errorDescription == expected)
        } catch {
            Issue.record("Beklenmeyen hata: \(error)")
        }

        #expect(counter.count == 0)
    }

    @Test func unauthorizedResponseTriggersSessionExpiry() async {
        let counter = CallCounter()
        let manager = TestNetwork.makeManager(counter: counter)
        TestNetwork.respond(status: 401, json: #"{"message": "Invalid token"}"#)

        do {
            _ = try await manager.request(PostEndpoint.feed, as: [Post].self)
            Issue.record("Hata bekleniyordu")
        } catch let error as NetworkError {
            guard case .unauthorized(let message) = error else {
                Issue.record("`.unauthorized` bekleniyordu, gelen: \(error)")
                return
            }
            #expect(message == "Invalid token")
        } catch {
            Issue.record("Beklenmeyen hata: \(error)")
        }

        #expect(counter.count == 1)
    }

    /// Login'de yanlış şifre gibi public endpoint 401'leri oturumu sonlandırmamalı.
    @Test func unauthorizedOnPublicEndpointIsServerError() async {
        let counter = CallCounter()
        let manager = TestNetwork.makeManager(token: nil, counter: counter)
        TestNetwork.respond(status: 401, json: #"{"message": "Hatalı şifre"}"#)

        do {
            _ = try await manager.request(AuthEndpoint.login(LoginRequest(emailOrUsername: "emre", password: "x")), as: LoginResponse.self)
            Issue.record("Hata bekleniyordu")
        } catch let error as NetworkError {
            guard case .server(401, let message) = error else {
                Issue.record("`.server(401)` bekleniyordu, gelen: \(error)")
                return
            }
            #expect(message == "Hatalı şifre")
        } catch {
            Issue.record("Beklenmeyen hata: \(error)")
        }

        #expect(counter.count == 0)
    }

    @Test func invalidJSONThrowsDecodingError() async {
        let manager = TestNetwork.makeManager()
        TestNetwork.respond(status: 200, json: #"{"unexpected": 1}"#)

        do {
            _ = try await manager.request(NotificationEndpoint.hasUnseen, as: HasUnseenResponse.self)
            Issue.record("Hata bekleniyordu")
        } catch let error as NetworkError {
            guard case .decoding = error else {
                Issue.record("`.decoding` bekleniyordu, gelen: \(error)")
                return
            }
        } catch {
            Issue.record("Beklenmeyen hata: \(error)")
        }
    }

    @Test func transportFailureThrowsTransportError() async {
        let manager = TestNetwork.makeManager()
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            try await manager.request(NotificationEndpoint.markSeen(id: "n1"))
            Issue.record("Hata bekleniyordu")
        } catch let error as NetworkError {
            guard case .transport = error else {
                Issue.record("`.transport` bekleniyordu, gelen: \(error)")
                return
            }
        } catch {
            Issue.record("Beklenmeyen hata: \(error)")
        }
    }

    @Test func uploadSendsMultipartBody() async throws {
        let manager = TestNetwork.makeManager(token: "upload-token")
        TestNetwork.respond(status: 200, json: #"{"url": "https://cdn.test/image.jpg"}"#)

        var form = MultipartFormData(boundary: "TEST-BOUNDARY")
        form.append(name: "type", value: UploadFolder.posts)
        let response = try await manager.upload(UploadEndpoint.image, form: form, as: UploadResponse.self)

        #expect(response.url == "https://cdn.test/image.jpg")
        let sent = try #require(MockURLProtocol.receivedRequests.first)
        #expect(sent.httpMethod == "POST")
        #expect(sent.value(forHTTPHeaderField: "Content-Type") == "multipart/form-data; boundary=TEST-BOUNDARY")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer upload-token")
    }
}

// MARK: - Yardımcı tipler

struct NetworkErrorTests {

    @Test func errorBodyParsing() {
        #expect(APIErrorBody.message(from: Data(#"{"message": "a"}"#.utf8)) == "a")
        #expect(APIErrorBody.message(from: Data(#"{"error": "b"}"#.utf8)) == "b")
        #expect(APIErrorBody.message(from: Data("düz metin".utf8)) == "düz metin")
        #expect(APIErrorBody.message(from: Data("<html>Error</html>".utf8)) == nil)
        #expect(APIErrorBody.message(from: Data(#"{"other": 1}"#.utf8)) == nil)
        #expect(APIErrorBody.message(from: Data()) == nil)
    }

    @Test func errorFlagsAndMessages() {
        #expect(NetworkError.unauthorized(message: nil).isUnauthorized)
        #expect(!NetworkError.server(statusCode: 500, message: nil).isUnauthorized)
        #expect(NetworkError.transport(URLError(.cancelled)).isCancelled)
        #expect(!NetworkError.transport(URLError(.timedOut)).isCancelled)
        #expect(NetworkError.transport(URLError(.notConnectedToInternet)).errorDescription == "İnternet bağlantısı yok")
        #expect(NetworkError.server(statusCode: 500, message: nil).errorDescription == "İşlem başarısız. (Kod: 500)")
    }

    @Test func decoderParsesBackendDates() throws {
        struct Dated: Decodable { let createdAt: Date }

        let withMillis = try JSONDecoder.api.decode(Dated.self, from: Data(#"{"createdAt": "2025-05-21T10:15:30.123Z"}"#.utf8))
        let withoutMillis = try JSONDecoder.api.decode(Dated.self, from: Data(#"{"createdAt": "2025-05-21T10:15:30Z"}"#.utf8))

        #expect(abs(withMillis.createdAt.timeIntervalSince(withoutMillis.createdAt) - 0.123) < 0.001)
        #expect(throws: DecodingError.self) {
            try JSONDecoder.api.decode(Dated.self, from: Data(#"{"createdAt": "21.05.2025"}"#.utf8))
        }
    }

    @Test func multipartEncodingIsClosed() {
        var form = MultipartFormData(boundary: "B")
        form.append(name: "type", value: "posts")
        let body = String(decoding: form.encoded(), as: UTF8.self)

        #expect(body.hasPrefix("--B\r\nContent-Disposition: form-data; name=\"type\"\r\n\r\nposts\r\n"))
        #expect(body.hasSuffix("--B--\r\n"))
    }
}
