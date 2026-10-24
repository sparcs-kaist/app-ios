//
//  PostImagesStrip.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

struct PostImagesStrip: View {
  let images: [FeedImage]
  private let hPadding: CGFloat = 16 // match your .padding(.horizontal, 16)

  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(SpoilerContents.self) private var spoilerContents

  @State private var parentWidth: CGFloat = 0
  @State private var gallery: ImageGallery?
  @Namespace private var imageTransition
  /// The image the strip is scrolled to, kept in step with the full-screen viewer.
  @State private var scrolledImageID: String?

  /// 400 pt would all but fill a short screen (landscape, or the outer display
  /// of iPhone Duo), leaving no room for the post around the image.
  private var maxImageHeight: CGFloat {
    verticalSizeClass == .compact ? 240 : 400
  }

  var body: some View {
    // Zero until measured, which happens in the same layout pass, so images are
    // only ever sized to the column they are actually in.
    let contentWidth = max(0, parentWidth - hPadding * 2)
    
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(images) { item in
          FeedLazyImage(
            item: item,
            maxWidth: contentWidth,
            maxHeight: maxImageHeight,
            onTap: { openGallery(at: item) }
          )
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .matchedTransitionSource(id: item.url, in: imageTransition)
        }
      }
      .padding(.horizontal, hPadding)
      .scrollTargetLayout()
    }
    .scrollPosition(id: $scrolledImageID, anchor: .center)
    // Let images continue through the margins around the capped feed column.
    // The enclosing feed scroll view still clips them at the viewport edge.
    .scrollClipDisabled()
    // Not `measureWidth`: its preference never reported while the strip was still zero high,
    // so the images stayed unsized.
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { parentWidth = $0 }
    .fullScreenCover(item: $gallery) { gallery in
      FullScreenImageViewer(gallery: gallery, transitionNamespace: imageTransition) { url in
        scrolledImageID = images.first { $0.url == url }?.id
      }
    }
  }

  /// The post's images to swipe through, leaving out spoilers that are still covered.
  private func openGallery(at item: FeedImage) {
    let visible = images.filter { $0.spoiler != true || spoilerContents.contains($0.id) }
    gallery = ImageGallery(urls: visible.map(\.url), selected: item.url)
  }
}
