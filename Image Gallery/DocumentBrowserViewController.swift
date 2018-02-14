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
    }
    
    private var template: URL?
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        importHandler(template, .copy)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        let storyBoard = UIStoryboard(name: Storyboard.main, bundle: nil)
        let documentController = storyBoard.instantiateViewController(withIdentifier: Storyboard.document)
        if let imageGalleryViewController = documentController.contents as? ImageGalleryViewController {
            imageGalleryViewController.document = ImageGalleryDocument(fileURL: documentURL)
        }
        present(documentController, animated: true)
    }
}

