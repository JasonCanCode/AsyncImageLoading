# AsyncImageLoading

A light-weight solution for loading and caching images.

## Overview

Use the singleton of `AsyncImageLoader` to fetch your image on a background thread before updating on the main thread. If you have already fetched an image at the provided URL during your app session, a cached image previously fetched will be returned.

```swift
AsyncImageLoader.shared.updateImage(
    fromURLString: user.profileImagePath, 
    placeholderImage: UIImage(systemName: "photo")
) { [weak self] newImage, _ in
    if let newImage = newImage {
        self?.image = newImage
    }
}
```

## UIKit

Use `AsyncUIImageView` in your custom table view cells to easily load your thumbnail images. The function for updating the image of this view has a safeguard against loading a stale image so you won't see mismatched images when power-scrolling through a table view. If you want to be extra careful you can also set the image to nil when preparing your cell for reuse. 

```swift
if let userCell = cell as? UserCell {
    let uiModel = uiModels[indexPath.row]
    userCell.profileImage.updateImage(fromURL: uiModel.imageURL)
    // ...
}
```

## SwiftUI

Use `AsyncImage` in your custom views for populating lists in SwiftUI. 

```swift
AsyncImage(url: uiModel.imageURL)
```

If you'd like your view to show a loading spinner while the image is being fetched and a backup view if the fetch fails, you can provide your own ViewBuilders.

```swift
AsyncImage(
    url: uiModel.imageURL,
    contentMode: .fill,
    loadingView: { ProgressView() },
    failureView: { Image(systemName: "photo") }
)
```

## Placeholders

When you provide a placeholder image, `AsyncImageLoader` will provide that back immediately through the provided handler if a cached image is not found. It will then perform the image download and provide the desired image once complete. Should any issue occur with the image download, the completion handler will instead receive a `nil` image and the coorisponding error. Let's take another look at our first code example...

```swift
AsyncImageLoader.shared.updateImage(
    fromURLString: user.profileImagePath, 
    placeholderImage: UIImage(systemName: "photo")
) { [weak self] newImage, _ in
    if let newImage = newImage {
        self?.image = newImage
    }
}
```

If we are using this to load a profile photo, the screen will first appear with the SFSymbol as their picture. Their actual photo will download in the background and replace the placeholder image once complete. Should the download fail, the placeholder would remain because we are only updating `self.image` when a new photo is provided and failure means a `nil` value is passed to the completion handler. 

> [!NOTE]
> This is how it works when you provide a placeholder image to `AsyncUIImageView` but as of right now `AsyncImage` does not make use of this. If you want the same behavior with an `AsyncImage` you'll need to provide it within your `loadingView` and `failureView` view builders.
