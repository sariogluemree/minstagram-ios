//
//  NetworkLogger.swift
//  minstagram
//

import Foundation

/// Sadece DEBUG build'lerde loglar. `Authorization` header'ı ve token asla loglanmaz.
enum NetworkLogger {

    static func log(request: URLRequest) {
        #if DEBUG
        print("➡️ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "-")")
        #endif
    }

    static func log(response: HTTPURLResponse, data: Data, for request: URLRequest, duration: TimeInterval) {
        #if DEBUG
        let status = response.statusCode
        let icon = (200..<300).contains(status) ? "✅" : "⚠️"
        let ms = Int(duration * 1000)
        print("\(icon) \(status) \(request.httpMethod ?? "?") \(request.url?.path ?? "-") (\(ms) ms)")
        if !(200..<300).contains(status), let body = String(data: data, encoding: .utf8), !body.isEmpty {
            print("   ↳ \(body.prefix(500))")
        }
        #endif
    }

    static func log(error: Error, for request: URLRequest) {
        #if DEBUG
        print("❌ \(request.httpMethod ?? "?") \(request.url?.path ?? "-") → \(error)")
        #endif
    }

    static func log(decodingError: Error, data: Data, for request: URLRequest) {
        #if DEBUG
        print("❌ Decode hatası \(request.url?.path ?? "-"): \(decodingError)")
        if let body = String(data: data, encoding: .utf8) {
            print("   ↳ \(body.prefix(1000))")
        }
        #endif
    }
}
