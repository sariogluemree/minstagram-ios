//
//  MultipartFormData.swift
//  minstagram
//

import UIKit

struct MultipartFormData {
    let boundary: String
    private var body = Data()

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func append(name: String, value: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func append(name: String, fileName: String, mimeType: String, data: Data) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        append("\r\n")
    }

    /// Kapanış boundary'si eklenmiş gövde.
    func encoded() -> Data {
        var result = body
        result.append(Data("--\(boundary)--\r\n".utf8))
        return result
    }

    private mutating func append(_ string: String) {
        body.append(Data(string.utf8))
    }
}

extension MultipartFormData {
    /// `POST upload` için form: `type` (Cloudinary klasörü) + `image` (JPEG).
    static func image(_ image: UIImage, type: String, compressionQuality: CGFloat = 0.8) throws -> MultipartFormData {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw NetworkError.encoding(CocoaError(.coderInvalidValue))
        }
        var form = MultipartFormData()
        form.append(name: "type", value: type)
        form.append(name: "image", fileName: "image.jpg", mimeType: "image/jpeg", data: data)
        return form
    }
}
