//
//  DocumentBrowserViewController.swift
//  Documents
//
//  Created by Denis Avdeev on 14.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    private struct Constants {
        static let mainStoryboard = "Main"
        static let documentIdentifier = "Document"
        static let templateFileName = "Untitled.gallery"
        static let imageCacheMemoryCapacity = 100_000_000   // Worth ~100 photos or a dozen galleries.
        static let imageCacheDiskCapacity = 200_000_000     // Twice the size of the memory limit.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        allowsPickingMultipleItems = false
        allowsDocumentCreation = false
        if UIDevice.current.userInterfaceIdiom == .pad {
            template = try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
                ).appendingPathComponent(Constants.templateFileName)
            if template != nil {
                allowsDocumentCreation = FileManager.default.createFile(atPath: template!.path, contents: Data())
            }
        }
        URLCache.shared = URLCache(
            memoryCapacity: Constants.imageCacheMemoryCapacity,
            diskCapacity: Constants.imageCacheDiskCapacity,
            diskPath: nil
        )
    }
    
    private var template: URL?
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        importHandler(template, .copy)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        presentDocument(at: documentURLs.first)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    /// Presents a document modally and if possible sets its `document` property
    /// to an instance of `Document` with `documentURL` as document's URL.
    func presentDocument(at documentURL: URL?) {
        let storyBoard = UIStoryboard(name: Constants.mainStoryboard, bundle: nil)
        let documentController = storyBoard.instantiateViewController(withIdentifier: Constants.documentIdentifier)
        if let galleryController = documentController.contents.contents as? ImageGalleryViewController, documentURL != nil {
            galleryController.document = Document(fileURL: documentURL!)
        }
        present(documentController, animated: true)
    }
}

