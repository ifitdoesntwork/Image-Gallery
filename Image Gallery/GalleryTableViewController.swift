//
//  GalleryTableViewController.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 11.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class GalleryTableViewController: UITableViewController, ImageGalleryViewControllerDelegate, GalleryTableViewCellDelegate, UISplitViewControllerDelegate {

    private struct Constants {
        static let cellReuseIdentifier = "Gallery Cell"
        static let newGalleryTitle = "Untitled"
        static let gallerySegueIdentifier = "Select Gallery"
        static let deletedGalleriesSectionTitle = "Recently Deleted"
        static let undeleteActionTitle = "Undelete"
        static let galleriesPersistanceKey = "Galleries"
        static let deletedGalleriesPersistanceKey = "Deleted Galleries"
        static let selectionTimer = 0.1
    }

    /// An array of the galleries data.
    var galleries = [Gallery]() {
        didSet {
            if let galleriesData = try? PropertyListEncoder().encode(galleries) {
                UserDefaults.standard.set(galleriesData, forKey: Constants.galleriesPersistanceKey)
            }
        }
    }
    
    /// An array of recently deleted galleries data.
    var deletedGalleries = [Gallery]() {
        didSet {
            if let galleriesData = try? PropertyListEncoder().encode(deletedGalleries) {
                UserDefaults.standard.set(galleriesData, forKey: Constants.deletedGalleriesPersistanceKey)
            }
        }
    }

    // MARK: - ImageGalleryViewControllerDelegate
    
    func gallerydidChangeModel(_ gallery: ImageGalleryViewController) {
        if gallery == seguedToGallery?.controller {
            galleries[seguedToGallery!.indexPath.row] = gallery.gallery!
        }
    }

    // MARK: - GalleryTableViewCellDelegate

    func cell(_ cell: GalleryTableViewCell, didEndEditingTitle title: String) {
        if let indexPath = tableView.indexPath(for: cell) {
            if indexPath.section == 0 {
                galleries[indexPath.row].title = title
                seguedToGallery?.controller.title = galleries[indexPath.row].title
            } else {
                deletedGalleries[indexPath.row].title = title
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return deletedGalleries.isEmpty ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : Constants.deletedGalleriesSectionTitle
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? galleries.count : deletedGalleries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath)
        let galleryArray = indexPath.section == 0 ? galleries : deletedGalleries
        if let galleryCell = cell as? GalleryTableViewCell {
            galleryCell.title.text = galleryArray[indexPath.row].title
            galleryCell.delegate = self
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates({
                if indexPath.section == 0 {
                    deletedGalleries.append(galleries[indexPath.row])
                    galleries.remove(at: indexPath.row)
                    if tableView.numberOfSections == 1 {
                        tableView.insertSections(IndexSet(integer: 1), with: .automatic)
                    }
                    tableView.insertRows(at: [IndexPath(row: deletedGalleries.count - 1, section: 1)], with: .automatic)
                    if let selectedIndexPath = seguedToGallery?.indexPath, selectedIndexPath.row >= indexPath.row {
                        let newSelectedRow = selectedIndexPath.row > 0 ? selectedIndexPath.row - 1 : selectedIndexPath.row
                        seguedToGallery?.indexPath = IndexPath(row: newSelectedRow, section: 0)
                        if selectedIndexPath.row == indexPath.row && galleries.count > 0 {
                            performSegue(withIdentifier: Constants.gallerySegueIdentifier, sender: tableView.cellForRow(at: seguedToGallery!.indexPath))
                        }
                    }
                    haveAtLeastOneGallery()
                } else {
                    deletedGalleries.remove(at: indexPath.row)
                    if deletedGalleries.isEmpty {
                        tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
                    }
                }
                tableView.deleteRows(at: [indexPath], with: .automatic)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        Timer.scheduledTimer(withTimeInterval: Constants.selectionTimer, repeats: false) { [weak self] _ in
            if let selectedIndexPath = self?.seguedToGallery?.indexPath {
                self?.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
            }
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else {
            return nil
        }
        let action = UIContextualAction(style: .normal, title: Constants.undeleteActionTitle) { (_, _, completion) in
            tableView.performBatchUpdates({ [weak self, unowned tableView] in
                guard self != nil else {
                    completion(false)
                    return
                }
                self!.galleries.append(self!.deletedGalleries.remove(at: indexPath.row))
                tableView.deleteRows(at: [indexPath], with: .automatic)
                if self!.deletedGalleries.isEmpty {
                    tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
                }
                tableView.insertRows(at: [IndexPath(row: self!.galleries.count - 1, section: 0)], with: .automatic)
                completion(true)
            })
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }

    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return seguedToGallery == nil
    }

    // MARK: - Actions
    
    @IBAction private func addGallery() {
        galleries += [Gallery(
            title: Constants.newGalleryTitle.madeUnique(withRespectTo: (galleries + deletedGalleries).flatMap { $0.title }),
            images: [Gallery.Image]()
        )]
        tableView.insertRows(at: [IndexPath(row: galleries.count - 1, section: 0)], with: .automatic)
    }
    
    private func haveAtLeastOneGallery() {
        if galleries.isEmpty {
            addGallery()
            selectFirstGallery()
        }
    }
    
    private func selectFirstGallery() {
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        performSegue(withIdentifier: Constants.gallerySegueIdentifier, sender: tableView.cellForRow(at: indexPath))
    }
    
    // MARK: - Navigation

    private var seguedToGallery: (indexPath: IndexPath, controller: ImageGalleryViewController)?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.gallerySegueIdentifier {
            if let destination = segue.destination.contents as? ImageGalleryViewController {
                if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                    seguedToGallery = (indexPath, destination)
                    destination.delegate = self
                    destination.title = galleries[indexPath.row].title
                    destination.gallery = galleries[indexPath.row]
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        splitViewController?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let galleriesData = UserDefaults.standard.value(forKey: Constants.galleriesPersistanceKey) as? Data {
            galleries = (try? PropertyListDecoder().decode([Gallery].self, from: galleriesData)) ?? galleries
        }
        if let galleriesData = UserDefaults.standard.value(forKey: Constants.deletedGalleriesPersistanceKey) as? Data {
            deletedGalleries = (try? PropertyListDecoder().decode([Gallery].self, from: galleriesData)) ?? deletedGalleries
        }
        haveAtLeastOneGallery()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if tableView.indexPathForSelectedRow == nil {
            selectFirstGallery()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if splitViewController?.preferredDisplayMode != .primaryOverlay {
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
    }

}
