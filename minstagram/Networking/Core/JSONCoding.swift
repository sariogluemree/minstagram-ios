//
//  JSONCoding.swift
//  minstagram
//

import Foundation

extension JSONDecoder {
    /// Backend (Mongo) tarihleri ISO8601 + milisaniye formatında döner: `2025-05-21T10:15:30.123Z`.
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = withFractional.date(from: string) ?? withoutFractional.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Beklenmeyen tarih formatı: \(string)")
        }
        return decoder
    }()
}

extension JSONEncoder {
    static let api = JSONEncoder()
}
