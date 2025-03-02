//
//  APIErrorResponse.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 2.03.2025.
//


import Foundation

struct APIMessageResponse: Decodable {
    let message: String
}

func handleMessage(data: Data) -> String? {
    do {
        let messageResponse = try JSONDecoder().decode(APIMessageResponse.self, from: data)
        return messageResponse.message
    } catch {
        return "Mesaj alınırken bir hata meydana geldi."
    }
}
