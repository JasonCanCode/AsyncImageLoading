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

    /// Load an image on a separate thread and use the result to update on the main thread.
    /// - Parameters:
    ///   - urlString: Converted into a `URL` for requesting an image.
    ///   - placeholderImage: Optional image to apply using the provided completion handler while the desired image is loading.
    ///
    ///   Upon completion of loading the image, we prioritize re-fetching the image from the image cache using the
    ///   retained ``urlString``. This is to prevent updating with a stale image that was returned after a cell using
    ///   this view has been dequeued.
    public func updateImage(fromURLString urlString: String?, placeholderImage: UIImage? = nil) {
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

    /// Load an image on a separate thread and use the result to update on the main thread.
    /// - Parameters:
    ///   - url: The source of the image to be fetched
    ///   - placeholderImage: Optional image to apply using the provided completion handler while the desired image is loading.
    ///
    ///   Upon completion of loading the image, we prioritize re-fetching the image from the image cache using the
    ///   retained ``urlString``. This is to prevent updating with a stale image that was returned after a cell using
    ///   this view has been dequeued.
    func updateImage(fromURL url: URL?, placeholderImage: UIImage? = nil) {
        updateImage(fromURLString: url?.absoluteString, placeholderImage: placeholderImage)
    }
}
