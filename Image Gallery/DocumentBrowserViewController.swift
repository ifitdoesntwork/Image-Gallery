//
//  DocumentBrowserViewController.swift
//  Documents
//
//  Created by Denis Avdeev on 14.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    private struct Storyboard {
        static let main = "Main"
        static let document = "Document"
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
                ).appendingPathComponent(Storyboard.templateFileName)
            if template != nil {
                allowsDocumentCreation = FileManager.default.createFile(atPath: template!.path, contents: Data())
            }
        }
        URLCache.shared = URLCache(
            memoryCapacity: Storyboard.imageCacheMemoryCapacity,
            diskCapacity: Storyboard.imageCacheDiskCapacity,
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
    
    func presentDocument(at documentURL: URL?) {
        let storyBoard = UIStoryboard(name: Storyboard.main, bundle: nil)
        let documentController = storyBoard.instantiateViewController(withIdentifier: Storyboard.document)
        if let galleryController = documentController.contents as? ImageGalleryViewController, let url = documentURL {
            galleryController.document = ImageGalleryDocument(fileURL: url)
        }
        present(documentController, animated: true)
    }
}

