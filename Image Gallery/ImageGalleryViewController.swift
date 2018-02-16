//
//  ImageCollectionViewController.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 10.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIDropInteractionDelegate, UICollectionViewDropDelegate, UICollectionViewDragDelegate {

    private struct Cell {
        static let reuseIdentifier = "Image Cell"
        static let placeholderReuseIdentifier = "Drop Placeholder Cell"
        static let width: CGFloat = 200.0
        static let segueIdentifier = "Show Image"
        static let imageTitle = "Image"
    }
    
    /// The image gallery document.
    var document: Document?
    
    /// The gallery data model.
    var gallery: Gallery? {
        get {
            let images = imagesData.map { imageData in
                Gallery.Image(
                    url: imageData.url,
                    heightToWidthRatio: Double(imageData.heightToWidthRatio)
                )
            }
            return Gallery(images: images)
        }
        set {
            imagesData = newValue?.images.map { ($0.url, CGFloat($0.heightToWidthRatio)) } ?? []
            collectionView?.reloadData()
        }
    }
    
    private typealias ImageData = (url: URL, heightToWidthRatio: CGFloat)
    
    private var imagesData = [ImageData]() {
        didSet {
            makeSureCellsFitViewHeight()
            document?.gallery = gallery
            document?.updateChangeCount(.done)
        }
    }
    
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet private weak var trashCan: UIButton! {
        didSet {
            trashCan.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesData.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.imageURL = imagesData[indexPath.item].url
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
            return imagesData.indices.reduce(CGFloat.infinity) { maxCellWidth, imageIndex in
                let widthForMaximumHeight = maxCellHeight / imagesData[imageIndex].heightToWidthRatio
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
        return CGSize(width: cellWidth, height: cellWidth * imagesData[indexPath.item].heightToWidthRatio)
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
        let image = imagesData[indexPath.item]
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image.url as NSItemProviderWriting))
        dragItem.localObject = (indexPath, image)
        return [dragItem]
    }
    
    // MARK: - UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard document?.documentState == .normal else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
        let isSelf = session.localDragSession?.localContext as? UICollectionView == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: collectionView.numberOfItems(inSection: 0), section: 0)
        coordinator.items.forEach { item in
            if let sourceIndexPath = item.sourceIndexPath {
                if let sourceImage = (item.dragItem.localObject as? (IndexPath, ImageData))?.1 {
                    if destinationIndexPath.item == imagesData.count {
                        destinationIndexPath.item -= 1
                    }
                    collectionView.performBatchUpdates({
                        imagesData.remove(at: sourceIndexPath.item)
                        imagesData.insert(sourceImage, at: destinationIndexPath.item)
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
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { [weak placeholderContext] (provider, error) in
                    DispatchQueue.main.async { [weak self] in
                        if let url = provider as? URL, let context = placeholderContext {
                            self?.completeLoadingOfImage(at: imageIndex, in: context, loadedUrl: url.imageURL, loadedRatio: nil)
                        } else {
                            placeholderContext?.deletePlaceholder()
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { [weak placeholderContext] (provider, error) in
                    DispatchQueue.main.async { [weak self] in
                        if let image = provider as? UIImage, let context = placeholderContext {
                            self?.completeLoadingOfImage(at: imageIndex, in: context, loadedUrl: nil, loadedRatio: image.size.height / image.size.width)
                        } else {
                            placeholderContext?.deletePlaceholder()
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
                imagesData.insert((url, ratio), at: insertionIndexPath.item)
            }
        }
    }
    
    // MARK: - UIDropInteractionDelegate
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let isSelf = session.localDragSession?.localContext as? UICollectionView == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .copy : .cancel)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.localDragSession?.items.forEach { item in
            if let sourceIndexPath = (item.localObject as? (IndexPath, ImageData))?.0 {
                collectionView?.performBatchUpdates({
                    imagesData.remove(at: sourceIndexPath.item)
                    collectionView?.deleteItems(at: [sourceIndexPath])
                })
            }
        }
    }

    // MARK: - Actions
    
    @IBAction private func close(_ sender: UIBarButtonItem) {
        let snapshotView = UIView(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        (0...1).forEach { column in
            (0...1).forEach { row in
                let index = row * 2 + column
                if imagesData.count > index {
                    if let imageData = imagesData[index].url.cachedContents(creatingCacheIfNoneAvailable: false) {
                        let subview = UIImageView(image: UIImage(data: imageData))
                        subview.frame = CGRect(x: 512 * CGFloat(row), y: 512 * CGFloat(column), width: 512, height: 512)
                        subview.contentMode = .scaleAspectFit
                        snapshotView.addSubview(subview)
                    }
                }
            }
        }
        document?.thumbnail = snapshotView.snapshot
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Cell.segueIdentifier, let cell = sender as? ImageCollectionViewCell, let indexPath = collectionView?.indexPath(for: cell) {
            if let destination = segue.destination as? ImageViewController {
                destination.imageURL = imagesData[indexPath.item].url
                destination.title = Cell.imageTitle
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.dragDelegate = self
        collectionView?.dropDelegate = self
        collectionView?.dragInteractionEnabled = true
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(ImageGalleryViewController.pinch(_:)))
        collectionView?.addGestureRecognizer(pinch)
        if document == nil {
            if let galleries = Document.localGalleries, let firstGallery = galleries.galleries.first {
                let firstDocument = galleries.url.appendingPathComponent(firstGallery)
                document = Document(fileURL: firstDocument)
            } else {
                document = Document.makeLocalDocument()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if document?.documentState == .closed {
            document?.open { [weak self] success in
                if success {
                    self?.title = self?.document?.localizedName
                    self?.trashCan.isEnabled = true
                    self?.gallery = self?.document?.gallery
                }
                self?.spinner.stopAnimating()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        makeSureCellsFitViewHeight()
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
