//
//  ImageCollectionViewCell.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 10.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    /// The cell's image URL.
    var imageURL: URL? {
        didSet {
            fetchImage()
        }
    }
    
    @IBOutlet private weak var imageView: UIImageView!
    
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet private weak var errorLabel: UILabel!
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            spinner.stopAnimating()
            errorLabel.isHidden = true
        }
    }

    private func fetchImage() {
        if let url = imageURL {
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        image = nil
    }
    
}
