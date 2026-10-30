//
//  PostImagesStrip.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import BuddyDomain

struct PostImagesStrip: View {
  let images: [FeedImage]
  private let hPadding: CGFloat = 16 // match your .padding(.horizontal, 16)

  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.feedColumnWidth) private var feedColumnWidth

  @State private var parentWidth: CGFloat = 0
  @State private var selectedImage: FeedImage?

  /// 400 pt would all but fill a short screen (landscape, or the outer display
  /// of iPhone Duo), leaving no room for the post around the image.
  private var maxImageHeight: CGFloat {
    verticalSizeClass == .compact ? 240 : 400
  }

  var body: some View {
    // Until the strip has measured itself, size to the column the feed reports.
    // The feed's lazy stack rebuilds rows as they scroll back in, and a strip
    // that started at zero and grew a frame later shifted the rows below it,
    // making the feed jump while scrolling up.
    let columnWidth = parentWidth > 0 ? parentWidth : feedColumnWidth
    let contentWidth = max(0, columnWidth - hPadding * 2)
    
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(images) { item in
          FeedLazyImage(
            item: item,
            maxWidth: contentWidth,
            maxHeight: maxImageHeight,
            onTap: { selectedImage = item }
          )
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
      }
      .padding(.horizontal, hPadding)
    }
    // Let images continue through the margins around the capped feed column.
    // The enclosing feed scroll view still clips them at the viewport edge.
    .scrollClipDisabled()
    // Not `measureWidth`: its preference never reported while the strip was still zero high,
    // so the images stayed unsized.
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { parentWidth = $0 }
    .fullScreenCover(item: $selectedImage) { item in
      FullScreenImageViewer(url: item.url)
    }
  }
}

extension EnvironmentValues {
  /// Width of the feed's content column, measured once by the feed so rows
  /// rebuilt by its lazy stack can size their images on their first layout.
  @Entry var feedColumnWidth: CGFloat = 0
}
