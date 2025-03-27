//
//  UIImageView+Extensions.swift
//  minstagram
//
//  Created by Hüseyin Emre Sarıoğlu on 5.03.2025.
//

import UIKit

extension UIImageView {
    func loadImage(from urlString: String, placeholder: String? = nil) {
        // Eğer placeholder varsa, önce onu göster
        if let placeholder = placeholder {
            self.image = UIImage(named: placeholder)
        }

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }.resume()
    }
}
