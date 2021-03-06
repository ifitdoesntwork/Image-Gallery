//
//  Gallery.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 14.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import Foundation

struct Gallery: Codable {
    /// The gallery images data.
    var images: [Image]
    
    struct Image: Codable {
        /// The image URL; the relative path is stored for local images.
        var url: URL
        
        /// The image height to width ratio.
        var heightToWidthRatio: Double
    }
    
    /// The gallery data encoded as a property list.
    var propertyList: Data? {
        return try? PropertyListEncoder().encode(self)
    }
    
    init?(propertyList: Data) {
        if let newValue = try? PropertyListDecoder().decode(Gallery.self, from: propertyList) {
            self = newValue
        } else {
            return nil
        }
    }
    
    init(images: [Image]) {
        self.images = images
    }
}
