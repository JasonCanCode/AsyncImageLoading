//
//  AsyncUIImageView.swift
//
//  Created by Jason Welch on 1/25/24.
//

import UIKit

/// Subclass of `UIImageView` that allows you to safely load images asynchronously
open class AsyncUIImageView: UIImageView {
    /// The path used to load the image.
    public private(set) var urlString: String?

    public func updateImage(fromURLString urlString: String, placeholderImage: UIImage? = nil) {
        let placeholderImage = placeholderImage ?? self.image
        self.urlString = urlString

        AsyncImageLoader
            .shared
            .updateImage(fromURLString: urlString, placeholderImage: placeholderImage) { [weak self] newImage, _ in
                if let newImage = newImage {
                    // Use the most recently cached image of the stored urlString if available to avoid an issue with dequeued cells
                    self?.image = AsyncImageLoader.shared.imageFromCache(self?.urlString) ?? newImage
                    self?.layoutIfNeeded()
                }
            }
    }
}
