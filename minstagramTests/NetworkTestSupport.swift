//
//  NetworkTestSupport.swift
//  minstagramTests
//

import Foundation
@testable import minstagram

/// Ağ çağrısı yapmadan `URLSession` yanıtlarını taklit eder.
/// Statik durum paylaşıldığı için bunu kullanan suite `.serialized` olmalı.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var receivedRequests: [URLRequest] = []

    static func reset() {
        handler = nil
        receivedRequests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.receivedRequests.append(request)
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

struct StubTokenProvider: TokenProviding {
    var token: String?
}

final class CallCounter {
    private(set) var count = 0
    func increment() { count += 1 }
}

enum TestNetwork {
    static let baseURL = URL(string: "https://test.local/api/")!

    static func makeManager(token: String? = "test-token", counter: CallCounter = CallCounter()) -> NetworkManager {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return NetworkManager(session: URLSession(configuration: configuration),
                              baseURL: baseURL,
                              tokenProvider: StubTokenProvider(token: token),
                              onUnauthorized: { counter.increment() })
    }

    static func respond(status: Int, json: String) {
        respond(status: status, data: Data(json.utf8))
    }

    static func respond(status: Int, data: Data) {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }
}
