//
//  GalleryTableViewCell.swift
//  Image Gallery
//
//  Created by Denis Avdeev on 11.02.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

class GalleryTableViewCell: UITableViewCell, UITextFieldDelegate {

    /// The gallery cell delegate.
    var delegate: GalleryTableViewCellDelegate?
    
    /// The text field with the title of the image gallery.
    @IBOutlet weak var title: UITextField!
    
    @objc private func editGalleryTitle(_ sender: UITapGestureRecognizer) {
        if let cell = sender.view as? GalleryTableViewCell, let textField = cell.title {
            textField.isEnabled = true
            textField.becomeFirstResponder()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(GalleryTableViewCell.editGalleryTitle(_:)))
        tap.numberOfTapsRequired = 2
        addGestureRecognizer(tap)
    }

    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.isEnabled = false
        delegate?.cell(self, didEndEditingTitle: textField.text ?? "")
    }

}

protocol GalleryTableViewCellDelegate {
    /// Informs the delegate that a `cell` just ended editing gallery `title`.
    func cell(_ cell: GalleryTableViewCell, didEndEditingTitle title: String)
}
