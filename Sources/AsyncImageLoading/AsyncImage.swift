//
//  AsyncImage.swift
//
//  Created by Jason Welch on 1/25/24.
//

import SwiftUI

/// A SwiftUI view that displays an asychronously loaded image
public struct AsyncImage<LoadingView: View, FailureView: View>: View {
    /// The source of the image to be fetched
    public let url: URL?
    /// Defines how the image fills the available space.
    public var contentMode: SwiftUI.ContentMode = .fill
    /// A view to display while the image is loading
    @ViewBuilder public let loadingView: () -> LoadingView
    /// A view to display if image loading fails
    @ViewBuilder public let failureView: () -> FailureView

    @State private var loadingState: LoadingState = .loading
    @State private var image: UIImage?

    public init(
        url: URL?,
        contentMode: SwiftUI.ContentMode,
        loadingView: @escaping () -> LoadingView,
        failureView: @escaping () -> FailureView
    ) {
        self.url = url
        self.contentMode = contentMode
        self.loadingView = loadingView
        self.failureView = failureView
    }

    public var body: some View {
        Color.clear
            .background {
                ZStack {
                    if loadingState == .loading {
                        loadingView()
                    }

                    if loadingState == .failure {
                        failureView()
                    }
                }
            }
            .background {
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .opacity(image == nil ? 0 : 1)
                    .aspectRatio(contentMode: contentMode)
            }
            .contentShape(Rectangle())
            .task(id: url) {
                do {
                    image = try await AsyncImageLoader.shared.updateImage(fromURL: url, placeholderImage: image)
                    loadingState = .success
                } catch {
                    loadingState = .failure
                }
            }
    }
}

// MARK: - Loading State

private extension AsyncImage {

    /// The state of image fetching
    enum LoadingState {
        /// The image is currently being fethed
        case loading
        /// The image was fetched successfully
        case success
        /// The image failed to be fetched
        case failure
    }

}

// MARK: - Convenience Initializers

public extension AsyncImage {

    /// Creates an image view that display nothing during the loading and failure states.
    ///
    /// - Parameters:
    ///   - url: The `URL` representing the location of a resource to be loaded.
    ///   - contentMode: Defines how the image fills the available space.
    init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill
    ) where LoadingView == EmptyView, FailureView == EmptyView {
        self.init(
            url: url,
            contentMode: contentMode,
            loadingView: EmptyView.init,
            failureView: EmptyView.init
        )
    }

    /// Creates an image view that shows a loading view while loading, but nothing in the case of failure.
    ///
    /// - Parameters:
    ///   - url: The `URL` representing the location of a resource to be loaded.
    ///   - contentMode: Defines how the image fills the available space.
    ///   - loadingView: The view to display while the resource is being loaded.
    init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill,
        @ViewBuilder loadingView: @escaping () -> LoadingView
    ) where LoadingView: View, FailureView == EmptyView {
        self.init(
            url: url,
            contentMode: contentMode,
            loadingView: loadingView,
            failureView: EmptyView.init
        )
    }

    /// Creates an image view that shows a failure view if loading fails, but nothing during loading.
    ///
    /// - Parameters:
    ///   - url: The `URL` representing the location of a resource to be loaded.
    ///   - contentMode: Defines how the image fills the available space.
    ///   - failureView: The view to display if the resource is unable to be fetched.
    init(
        url: URL?,
        contentMode: SwiftUI.ContentMode = .fill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) where LoadingView == EmptyView, FailureView: View {
        self.init(
            url: url,
            contentMode: contentMode,
            loadingView: EmptyView.init,
            failureView: failureView
        )
    }
}

// MARK: - Preview Provider

internal struct AsyncImagePreview: PreviewProvider {

    static let url = URL(string: "https://live.staticflickr.com/2377/5695397299_3877a7855c_b.jpg")

    /// The last charater in the URL is missing for testing purposes, should be `.jpg`
    static let badURL = URL(string: "https://live.staticflickr.com/2377/5695397299_3877a7855c_b.jp")

    static var previews: some View {
        ScrollView {
            VStack {
                Group {
                    AsyncImage(url: url)
                    AsyncImage(url: badURL)
                        .border(.red, width: 2)
                }
                .aspectRatio(1.5, contentMode: .fit)
            }
            .padding()
        }
    }

}
