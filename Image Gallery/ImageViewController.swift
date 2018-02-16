//
//  ImageViewController.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 11.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {

    private struct ZoomScale {
        static let minimum: CGFloat = 1 / 25
        static let maximum: CGFloat = 1.0
    }
    
    /// The image URL.
    var imageURL: URL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if imageView.image == nil {
            fetchImage()
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet private weak var errorLabel: UILabel!
    
    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = ZoomScale.minimum
            scrollView.maximumZoomScale = ZoomScale.maximum
            scrollView.delegate = self
            scrollView.addSubview(imageView)
        }
    }
    
    private var imageView = UIImageView()
    
    private func fetchImage() {
        if let url = imageURL {
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = url.cachedContents(creatingCacheIfNoneAvailable: true)
                DispatchQueue.main.async {
                    guard url == self?.imageURL else {
                        return
                    }
                    if let imageData = urlContents {
                        self?.image = UIImage(data: imageData)
                    }
                    if self?.image == nil {
                        self?.errorLabel.isHidden = false
                    }
                }
            }
        }
    }
    
}
