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
  private let maxImageHeight: CGFloat = 400

  @State private var parentWidth: CGFloat = 0
  @State private var selectedImage: FeedImage?

  var body: some View {
    // Fallback to screen width until we read the actual width
    let pw = parentWidth > 0 ? parentWidth : CGFloat.screenWidth
    let contentWidth = max(0, pw - hPadding * 2)
    
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
    .measureWidth { parentWidth = $0 }
    .fullScreenCover(item: $selectedImage) { item in
      FullScreenImageViewer(url: item.url)
    }
  }
}
