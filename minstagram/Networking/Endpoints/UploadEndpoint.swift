//
//  UploadEndpoint.swift
//  minstagram
//

import Foundation

enum UploadEndpoint: Endpoint {
    /// Multipart: `NetworkManager.upload(_:form:as:)` + `MultipartFormData.image(_:type:)` → `UploadResponse`
    case image

    var path: String { "upload" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { true }
}


/// Cloudinary klasörleri (backend `type` form alanı).
enum UploadFolder {
    static let posts = "posts"
    static let profilePhotos = "profilePhotos"
}
