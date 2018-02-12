//
//  GalleryTableViewController.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 11.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

struct Gallery: Codable {
    /// The gallery title.
    var title: String
    /// The gallery images data.
    var images: [ImageData]
}

class GalleryTableViewController: UITableViewController, ImageGalleryViewControllerDelegate, GalleryTableViewCellDelegate {

    private struct Constants {
        static let cellReuseIdentifier = "Gallery Cell"
        static let genericGalleryTitle = "Untitled"
        static let gallerySegueIdentifier = "Select Gallery"
        static let deletedGalleriesSectionTitle = "Recently Deleted"
        static let undeleteActionTitle = "Undelete"
        static let galleriesPersistanceKey = "Galleries"
        static let deletedGalleriesPersistanceKey = "Deleted Galleries"
    }

    /// An array of pairs of `title` and image data (as `images`) of galleries.
    var galleries = [Gallery(title: Constants.genericGalleryTitle, images: [ImageData]())] {
        didSet {
            if let galleriesData = try? PropertyListEncoder().encode(galleries) {
                UserDefaults.standard.set(galleriesData, forKey: Constants.galleriesPersistanceKey)
            }
        }
    }
    
    /// An array of pairs of `title` and image data (as `images`) of recently deleted galleries.
    var deletedGalleries = [Gallery]() {
        didSet {
            if let galleriesData = try? PropertyListEncoder().encode(deletedGalleries) {
                UserDefaults.standard.set(galleriesData, forKey: Constants.deletedGalleriesPersistanceKey)
            }
        }
    }

    // MARK: - ImageGalleryViewControllerDelegate
    
    func gallerydidChangeModel(_ gallery: ImageGalleryViewController) {
        if let selectedCellIndex = tableView.indexPathForSelectedRow?.row, gallery == seguedToGallery {
            galleries[selectedCellIndex].images = gallery.images
        }
    }

    // MARK: - GalleryTableViewCellDelegate

    func cell(_ cell: GalleryTableViewCell, didEndEditingTitle title: String) {
        if let indexPath = tableView.indexPath(for: cell) {
            if indexPath.section == 0 {
                galleries[indexPath.row].title = title
                seguedToGallery?.title = galleries[indexPath.row].title
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
                    deletedGalleries.append(galleries.remove(at: indexPath.row))
                    if tableView.numberOfSections == 1 {
                        tableView.insertSections(IndexSet(integer: 1), with: .automatic)
                    }
                    tableView.insertRows(at: [IndexPath(row: deletedGalleries.count - 1, section: 1)], with: .automatic)
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

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1 else {
            return nil
        }
        let action = UIContextualAction(style: .normal, title: Constants.undeleteActionTitle) { (_, _, completion) in
            tableView.performBatchUpdates({ [weak self] in
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

    // MARK: - Actions
    
    @IBAction private func addGallery(_ sender: UIBarButtonItem) {
        galleries += [Gallery(
            title: Constants.genericGalleryTitle.madeUnique(withRespectTo: (galleries + deletedGalleries).map { $0.title }),
            images: [ImageData]()
            )]
        tableView.insertRows(at: [IndexPath(row: galleries.count - 1, section: 0)], with: .automatic)
    }
    
    // MARK: - Navigation

    private var seguedToGallery: ImageGalleryViewController?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.gallerySegueIdentifier {
            if let destination = segue.destination.contents as? ImageGalleryViewController {
                seguedToGallery = destination
                if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                    destination.delegate = self
                    destination.title = galleries[indexPath.row].title
                    destination.images = galleries[indexPath.row].images
                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            if indexPath.section == 1 {
                tableView.deselectRow(at: indexPath, animated: true)
                return false
            }
        }
        return true
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let galleriesData = UserDefaults.standard.value(forKey: Constants.galleriesPersistanceKey) as? Data {
            galleries = (try? PropertyListDecoder().decode([Gallery].self, from: galleriesData)) ?? galleries
        }
        if let galleriesData = UserDefaults.standard.value(forKey: Constants.deletedGalleriesPersistanceKey) as? Data {
            deletedGalleries = (try? PropertyListDecoder().decode([Gallery].self, from: galleriesData)) ?? deletedGalleries
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if splitViewController?.preferredDisplayMode != .primaryOverlay {
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
    }

}
