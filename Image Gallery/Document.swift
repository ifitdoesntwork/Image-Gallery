//
//  Document.swift
//  Documents
//
//  Created by Denis Avdeev on 14.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    private struct Constants {
        static let templateFileName = "Untitled"
        static let fileExtension = ".gallery"
    }
    
    /// The document's data.
    var gallery: Gallery?
    
    /// The document's thumbnail.
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
    
    /// Returns the title of a document produced by truncating
    /// file extension from the end of document's `fileName`.
    static func title(fromFileName fileName: String) -> String {
        let extensionStartIndex = fileName.index(fileName.endIndex, offsetBy: -Constants.fileExtension.count)
        return String(fileName[..<extensionStartIndex])
    }
    
    /// Returns the `fileName` of a document produced by appending
    /// file extension to the end of document's `title`.
    static func fileName(from title: String) -> String {
        return title + Document.Constants.fileExtension
    }
    
    /// A tuple containing local documents directory `url`, documents file names
    /// as `galleries`, and file names of recently deleted documents as `trash`.
    static var localGalleries: (url: URL, galleries: [String], trash: [String])? {
        if let documentsURL = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            let galleries = ((try? FileManager.default.contentsOfDirectory(atPath: documentsURL.path)) ?? []).filter {
                $0.hasSuffix(Constants.fileExtension)
            }
            let trash = ((try? FileManager.default.contentsOfDirectory(atPath: documentsURL.path + "/.Trash")) ?? []).filter {
                $0.hasSuffix(Constants.fileExtension)
            }
            return (documentsURL, galleries, trash)
        }
        return nil
    }
    
    /// Creates a local document with unique name.
    static func makeLocalDocument() -> Document? {
        if let locals = localGalleries {
            let galleriesTitles = locals.galleries.map { fileName in
                title(fromFileName: fileName)
            }
            let trashTitles = locals.trash.map { fileName in
                title(fromFileName: fileName)
            }
            let uniqueFileName = Constants.templateFileName.madeUnique(withRespectTo: galleriesTitles + trashTitles)
            let fileURL = locals.url.appendingPathComponent(uniqueFileName + Constants.fileExtension)
            if !FileManager.default.isReadableFile(atPath: fileURL.path) {
                do {
                    try Data().write(to: fileURL)
                    return Document(fileURL: fileURL)
                } catch let error {
                    print("Error creating empty file: \(error)")
                }
            }
        }
        return nil
    }
}

