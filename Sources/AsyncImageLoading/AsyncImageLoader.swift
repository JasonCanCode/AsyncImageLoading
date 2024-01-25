//
//  AsyncImageLoader.swift
//
//  Created by Jason Welch on 1/25/24.
//

import UIKit

// MARK: - ImageLoader Protocol

/// A code block that receives the result of attempting to load an image.
public typealias ImageLoaderHandler = (UIImage?, Error?) -> Void

/// An object capable of loading an image from a URL path and caching it for later retrieval.
public protocol ImageLoader {
    /// Attempt to retrieve an already loaded and cached image.
    /// - Parameters:
    ///   - urlString: The path used to load the image.
    ///   - Returns: The pre-loaded image, if available.
    func imageFromCache(_ urlString: String?) -> UIImage?
    /// Load an image on a separate thread and use the result in a provided completion block.
    /// - Parameters:
    ///   - urlString: Converted into a `URL` for requesting an image.
    ///   - placeholderImage: Optional image to apply using the provided completion handler while the desired image is loaded.
    ///   - completionHandler: A block that receives both a `UIImage` (on succuess) and an ``AsyncImageError`` (on failure).
    func updateImage(
        fromURLString urlString: String?,
        placeholderImage: UIImage?,
        completionHandler: @escaping ImageLoaderHandler
    )
}

public extension ImageLoader {
    /// Load an image on a separate thread and use the result in a provided completion block.
    /// - Parameters:
    ///   - url: The source of the image to be fetched
    ///   - placeholderImage: Optional image to apply using the provided completion handler while the desired image is loaded.
    ///   - completionHandler: A block that receives both a `UIImage` (on succuess) and an ``AsyncImageError`` (on failure).
    func updateImage(
        fromURL url: URL?,
        placeholderImage: UIImage? = nil,
        completionHandler: @escaping ImageLoaderHandler
    ) {
        updateImage(
            fromURLString: url?.absoluteString,
            placeholderImage: placeholderImage,
            completionHandler: completionHandler
        )
    }

    /// Load an image on a background thread before returning an image on the main thread.
    /// - Parameters:
    ///   - url: The source of the image to be fetched
    ///   - placeholderImage: Optional image to apply using the provided completion handler while the desired image is loaded.
    /// - Returns: A successfully loaded and cached image
    func updateImage(fromURL url: URL?, placeholderImage: UIImage? = nil) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            updateImage(fromURL: url, placeholderImage: placeholderImage) { image, error in
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    let error = error ?? AsyncImageError.faultyImageFromData
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Attempt to retrieve an already loaded and cached image.
    /// - Parameter url: The path used to load the image.
    /// - Returns: The pre-loaded image, if available.
    func imageFromCache(_ url: URL?) -> UIImage? {
        imageFromCache(url?.absoluteString)
    }
}

// MARK: - AsyncImageLoader class

/// Loads images asynchronously and caches the for quicker subsequent loads.
public class AsyncImageLoader: ImageLoader {
    private var task: URLSessionDownloadTask?
    private var session: URLSession
    private var imageCache: NSCache<AnyObject, UIImage>

    /// A singleton to be used throughout the lifecycle of the app.
    public private(set) static var shared = AsyncImageLoader(
        session: URLSession.shared,
        imageCache: NSCache<AnyObject, UIImage>()
    )

    /// Create an independent image loader, separate from the universal ``shared`` instance.
    /// - Parameters:
    ///   - session: The session performing the image download task.
    ///   - imageCache: The object used for retaining loaded images for reuse in subsequent loads.
    public init(session: URLSession, imageCache: NSCache<AnyObject, UIImage>) {
        self.task = nil
        self.session = session
        self.imageCache = imageCache
    }

    public func updateImage(fromURLString urlString: String?, placeholderImage: UIImage? = nil, completionHandler: @escaping ImageLoaderHandler) {

        // Threading for handlers
        let completeWithError: (AsyncImageError) -> Void = { customError in
            DispatchQueue.main.async {
                completionHandler(nil, customError)
            }
        }
        let completeWithImage: (UIImage) -> Void = { image in
            DispatchQueue.main.async {
                completionHandler(image, nil)
            }
        }

        if let img = imageFromCache(urlString) {
            // The image has already been loaded from the provided URL. We pull it from our cached images and forego the request.
            completeWithImage(img)
            return
        } else if let placeholder = placeholderImage {
            // Use completion block to insert the placeholder image while we are loading the actual image.
            completeWithImage(placeholder)
        }

        guard let urlString = urlString, let url = URL(string: urlString) else {
            completeWithError(.invalidURL)
            return
        }

        task = session.downloadTask(with: url, completionHandler: { _, _, error in
            // Attempt to load the image on a backgroung thread
            if let error = error {
                completeWithError(.downloadError(error: error))
                return

            } else if let data = try? Data(contentsOf: url) {

                if let img = UIImage(data: data) {
                    self.imageCache.setObject(img, forKey: urlString as AnyObject)
                    completeWithImage(img)
                } else {
                    completeWithError(.faultyImageFromData)
                }
                return
            } else {
                completeWithError(.faultyDataFromURL)
                return
            }
        })
        task?.resume()
    }

    public func imageFromCache(_ urlString: String?) -> UIImage? {
        guard let urlString = urlString else {
            return nil
        }

        return imageCache.object(forKey: urlString as AnyObject)
    }
}

// MARK: - Custom Errors

public enum AsyncImageError: Error {
    case invalidURL
    case downloadError(error: Error)
    case faultyDataFromURL
    case faultyImageFromData
}
