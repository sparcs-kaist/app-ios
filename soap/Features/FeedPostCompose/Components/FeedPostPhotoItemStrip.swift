//
//  FeedPostPhotoItemStrip.swift
//  soap
//
//  Created by Soongyu Kwon on 21/08/2025.
//

import SwiftUI
import NukeUI
import BuddyDomain

struct FeedPostPhotoItemStrip: View {
  @Binding var images: [FeedPostPhotoItem]
  private let hPadding: CGFloat = 16 // match your .padding(.horizontal, 16)

  @State private var parentWidth: CGFloat = 0

  var body: some View {
    // Fallback to screen width until we read the actual width
    let pw = parentWidth > 0 ? parentWidth : CGFloat.screenWidth
    let contentWidth = max(0, pw - hPadding * 2)
    let maxW = contentWidth
    let minW: CGFloat = 100
    let height = maxW * 3 / 4

    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach($images) { $item in
          let pixelSize = item.image.size
          let aspect = pixelSize.height > 0 ? pixelSize.width / pixelSize.height : 16.0 / 9.0
          let fitWidth = height * aspect
          let clampedWidth = min(max(fitWidth, minW), maxW)
          let shouldFill = !(minW...maxW).contains(fitWidth)

          Image(uiImage: item.image)
            .resizable()
            .aspectRatio(contentMode: shouldFill ? .fill : .fit)
            .frame(width: clampedWidth, height: height)
            .clipped()
            .clipShape(.rect(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
              Button("Toggle Spoiler", systemImage: item.spoiler ? "eye.slash" : "eye") {
                item.spoiler.toggle()
              }
              .labelStyle(.iconOnly)
              .padding(8)
              .font(.caption)
              .glassEffect(.regular.interactive(), in: .circle)
              .padding(8)
            }
        }
      }
      .padding(.horizontal, hPadding)
    }
    .frame(height: height)                 // fixes row height to 16:9 of parent width (minus padding)
    .measureWidth { parentWidth = $0 }     // read parent width
  }
}
