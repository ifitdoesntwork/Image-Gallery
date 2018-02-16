//
//  GalleryTableViewController.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 11.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class GalleryTableViewController: UITableViewController, GalleryTableViewCellDelegate {

    private struct Constants {
        static let cellReuseIdentifier = "Gallery Cell"
        static let gallerySegueIdentifier = "Select Gallery"
        static let deletedGalleriesSectionTitle = "Recently Deleted"
        static let undeleteActionTitle = "Undelete"
        static let selectionTimer = 0.1
    }

    private var documents: (url: URL, galleries: [String], trash: [String])?
    
    private func fetchDocuments() {
        documents = Document.localGalleries
    }

    // MARK: - GalleryTableViewCellDelegate

    func cell(_ cell: GalleryTableViewCell, didEndEditingTitle title: String) {
        guard documents != nil else {
            return
        }
        if let indexPath = tableView.indexPath(for: cell) {
            do {
                let sourceURL, destinationURL: URL
                if indexPath.section == 0 {
                    sourceURL = documents!.url.appendingPathComponent(documents!.galleries[indexPath.row])
                    destinationURL = documents!.url.appendingPathComponent(Document.fileName(from: title))
                } else {
                    sourceURL = documents!.url.appendingPathComponent(".Trash/" + documents!.trash[indexPath.row])
                    destinationURL = documents!.url.appendingPathComponent(".Trash/" + Document.fileName(from: title))
                }
                let needsSegue = indexPath == galleryInDetail?.indexPath
                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                fetchDocuments()
                tableView.reloadData()
                if needsSegue, let newCell = tableView.cellForRow(at: indexPath) {
                    performSegue(withIdentifier: Constants.gallerySegueIdentifier, sender: newCell)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
                selectRowFromDetail()
            } catch let error {
                print("Couldn't rename a gallery: \(error)")
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return documents?.trash.isEmpty ?? true ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : Constants.deletedGalleriesSectionTitle
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? documents?.galleries.count ?? 0 : documents?.trash.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath)
        if let galleryCell = cell as? GalleryTableViewCell {
            let fileName = (indexPath.section == 0 ? documents!.galleries : documents!.trash)[indexPath.row]
            galleryCell.title.text = Document.title(fromFileName: fileName)
            galleryCell.delegate = self
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let selectedIndexPath = galleryInDetail?.indexPath, selectedIndexPath == indexPath {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete && documents != nil else {
            return
        }
        tableView.performBatchUpdates({
            do {
                if indexPath.section == 0 {
                    let fileURL = documents!.url.appendingPathComponent(documents!.galleries[indexPath.row])
                    try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
                    fetchDocuments()
                    if tableView.numberOfSections == 1 {
                        tableView.insertSections(IndexSet(integer: 1), with: .automatic)
                    }
                    if let index = documents?.trash.index(of: fileURL.lastPathComponent) {
                        tableView.insertRows(at: [IndexPath(row: index, section: 1)], with: .automatic)
                    }
                } else {
                    let fileURL = documents!.url.appendingPathComponent(".Trash/" + documents!.trash[indexPath.row])
                    try FileManager.default.removeItem(at: fileURL)
                    fetchDocuments()
                    if documents!.trash.isEmpty {
                        tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
                    }
                }
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch let error {
                print("Couldn't delete a gallery: \(error)")
            }
        })
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        Timer.scheduledTimer(withTimeInterval: Constants.selectionTimer, repeats: false) { [weak self] _ in
            self?.selectRowFromDetail()
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else {
            return nil
        }
        let action = UIContextualAction(style: .normal, title: Constants.undeleteActionTitle) { (_, _, completion) in
            tableView.performBatchUpdates({ [weak self, unowned tableView] in
                guard self != nil, self?.documents != nil else {
                    completion(false)
                    return
                }
                do {
                    let fileName = self!.documents!.trash[indexPath.row]
                    let fileURL = self!.documents!.url.appendingPathComponent(".Trash/" + fileName)
                    try FileManager.default.moveItem(at: fileURL, to: self!.documents!.url.appendingPathComponent(fileName))
                    self!.fetchDocuments()
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    if self!.documents!.trash.isEmpty {
                        tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
                    }
                    if let index = self?.documents?.galleries.index(of: fileName) {
                        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                    completion(true)
                } catch let error {
                    print("Couldn't udelete a gallery: \(error)")
                    completion(false)
                }
            })
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }

    // MARK: - Actions
    
    @IBAction private func addGallery() {
        if let newDocument = Document.makeLocalDocument() {
            fetchDocuments()
            if let index = documents?.galleries.index(of: newDocument.fileURL.lastPathComponent) {
                tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
    }
    
    private func selectRowFromDetail() {
        if tableView.indexPathForSelectedRow == nil {
            tableView.selectRow(at: galleryInDetail?.indexPath, animated: true, scrollPosition: .none)
        }
    }

    // MARK: - Navigation

    private var galleryInDetail: (indexPath: IndexPath, controller: ImageGalleryViewController)? {
        if let detail = splitViewController?.viewControllers.last?.contents as? ImageGalleryViewController {
            if let url = detail.document?.fileURL, let localURL = documents?.url, url.path.hasPrefix(localURL.path) {
                if let index = documents?.galleries.index(of: url.lastPathComponent) {
                    return (IndexPath(row: index, section: 0), detail)
                }
            }
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.gallerySegueIdentifier {
            if let destination = segue.destination.contents as? ImageGalleryViewController {
                if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                    if let gallery = documents?.galleries[indexPath.row] {
                        destination.title = Document.title(fromFileName: gallery)
                        let document = documents!.url.appendingPathComponent(gallery)
                        destination.document = Document(fileURL: document)
                    }
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDocuments()
        tableView.reloadData()
        tableView.selectRow(at: galleryInDetail?.indexPath, animated: false, scrollPosition: .none)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if splitViewController?.preferredDisplayMode != .primaryOverlay {
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
    }

}
