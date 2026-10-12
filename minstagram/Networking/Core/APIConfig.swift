//
//  APIConfig.swift
//  minstagram
//

import Foundation

enum APIConfig {
    static let baseURL = URL(string: "http://localhost:5001/api/")!
    /// Backend'in bazı route'ları hata durumunda yanıt dönmüyor; istek sonsuza kadar asılı kalmasın.
    static let requestTimeout: TimeInterval = 30
}
