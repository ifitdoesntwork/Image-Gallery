//
//  ImageCollectionViewController.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 10.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

typealias ImageData = (url: URL, heightToWidthRatio: CGFloat)

class ImageGalleryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIDropInteractionDelegate, UICollectionViewDropDelegate, UICollectionViewDragDelegate {

    private struct Cell {
        static let reuseIdentifier = "Image Cell"
        static let placeholderReuseIdentifier = "Drop Placeholder Cell"
        static let width: CGFloat = 200.0
        static let segueIdentifier = "Show Image"
        static let imageTitle = "Image"
    }
    
    /// The image gallery delegate.
    var delegate: ImageGalleryViewControllerDelegate?
    
    /// An array of image data containing pairs of an image's `url` and its `heightToWidthRatio`.
    var images = [ImageData]() {
        didSet {
            delegate?.gallerydidChangeModel(self)
            makeSureCellsFitViewHeight()
        }
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.imageURL = images[indexPath.item].url
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate

    private var flowLayout: UICollectionViewFlowLayout? {
        return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    private var cellWidthToFitViewHeight: CGFloat {
        if let superview = collectionView {
            let maxCellHeight = superview.bounds.height - superview.layoutMargins.top - superview.layoutMargins.bottom
            return images.indices.reduce(CGFloat.infinity) { maxCellWidth, imageIndex in
                let widthForMaximumHeight = maxCellHeight / images[imageIndex].heightToWidthRatio
                return widthForMaximumHeight < maxCellWidth ? widthForMaximumHeight : maxCellWidth
            }
        } else {
            return 0
        }
    }
    
    private var cellWidth = Cell.width {
        didSet {
            makeSureCellsFitViewHeight()
            flowLayout?.invalidateLayout()
        }
    }
    
    private func makeSureCellsFitViewHeight() {
        if cellWidth > cellWidthToFitViewHeight {
            cellWidth = cellWidthToFitViewHeight
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth * images[indexPath.item].heightToWidthRatio)
    }
    
    // MARK: - UICollectionViewDragDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        let image = images[indexPath.item]
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image.url as NSItemProviderWriting))
        dragItem.localObject = image
        return [dragItem]
    }
    
    // MARK: - UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = session.localDragSession?.localContext as? UICollectionView == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: collectionView.numberOfItems(inSection: 0), section: 0)
        coordinator.items.forEach { item in
            if let sourceIndexPath = item.sourceIndexPath {
                if let sourceImage = item.dragItem.localObject as? (url: URL, heightToWidthRatio: CGFloat) {
                    if destinationIndexPath.item == images.count {
                        destinationIndexPath.item -= 1
                    }
                    collectionView.performBatchUpdates({
                        images.remove(at: sourceIndexPath.item)
                        images.insert(sourceImage, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                }
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            } else {
                let placeholder = UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: Cell.placeholderReuseIdentifier)
                let placeholderContext = coordinator.drop(item.dragItem, to: placeholder)
                let imageIndex = loadingImages.endIndex
                loadingImages.append((0, placeholderContext, nil, nil))
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    DispatchQueue.main.async { [weak self] in
                        if let url = provider as? URL {
                            self?.completeLoadingOfImage(at: imageIndex, in: placeholderContext, loadedUrl: url.imageURL, loadedRatio: nil)
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    DispatchQueue.main.async { [weak self] in
                        if let image = provider as? UIImage {
                            self?.completeLoadingOfImage(at: imageIndex, in: placeholderContext, loadedUrl: nil, loadedRatio: image.size.height / image.size.width)
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    private var loadingImages = [(index: Int, context: UICollectionViewDropPlaceholderContext, url: URL?, heightToWidthRatio: CGFloat?)]()

    private func completeLoadingOfImage(at index: Int, in placeholderContext: UICollectionViewDropPlaceholderContext, loadedUrl: URL?, loadedRatio: CGFloat?) {
        loadingImages[index].index = index
        if let url = loadedUrl {
            loadingImages[index].url = url
        }
        if let ratio = loadedRatio {
            loadingImages[index].heightToWidthRatio = ratio
        }
        let loadedImage = loadingImages[index]
        if let url = loadedImage.url, let ratio = loadedImage.heightToWidthRatio {
            placeholderContext.commitInsertion { insertionIndexPath in
                images.insert((url, ratio), at: insertionIndexPath.item)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Cell.segueIdentifier, let cell = sender as? ImageCollectionViewCell, let indexPath = collectionView?.indexPath(for: cell) {
            if let destination = segue.destination as? ImageViewController {
                destination.imageURL = images[indexPath.item].url
                destination.title = Cell.imageTitle
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.dragDelegate = self
        collectionView?.dropDelegate = self
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(ImageGalleryViewController.pinch(_:)))
        collectionView?.addGestureRecognizer(pinch)
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
    }
    
    @objc private func pinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed, .ended:
            cellWidth *= gesture.scale
            gesture.scale = 1.0
        default:
            break
        }
    }

}

protocol ImageGalleryViewControllerDelegate {
    /// Informs the delegate that a `gallery` chanded its `images` data model.
    func gallerydidChangeModel(_ gallery: ImageGalleryViewController)
}
