//
//  Document.swift
//  Documents
//
//  Created by Denis Avdeev on 14.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class ImageGalleryDocument: UIDocument {
    
    var gallery: Gallery?
    
    var thumbnail: UIImage?
    
    override func contents(forType typeName: String) throws -> Any {
        return gallery?.propertyList ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let propertyList = contents as? Data {
            gallery = Gallery(propertyList: propertyList)
        }
    }
    
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
        var attributes = try super.fileAttributesToWrite(to: url, for: saveOperation)
        if let thumbnail = self.thumbnail {
            attributes[URLResourceKey.thumbnailDictionaryKey] = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: thumbnail]
        }
        return attributes
    }
}

