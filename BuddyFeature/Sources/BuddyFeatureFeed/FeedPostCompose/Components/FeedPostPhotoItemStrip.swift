//
//  FeedPostPhotoItemStrip.swift
//  soap
//
//  Created by Soongyu Kwon on 21/08/2025.
//

import Foundation
import SwiftUI
import NukeUI
import BuddyDomain

struct FeedPostPhotoItemStrip: View {
  @Binding var images: [FeedPostPhotoItem]
  private let hPadding: CGFloat = 16 // match your .padding(.horizontal, 16)

  @Environment(\.verticalSizeClass) private var verticalSizeClass

  @State private var parentWidth: CGFloat = 0

  var body: some View {
    // Zero until measured, which happens in the same layout pass, so the strip
    // is only ever sized to the column it is actually in.
    let contentWidth = max(0, parentWidth - hPadding * 2)
    let maxW = contentWidth
    let minW: CGFloat = 100
    // 3:4 of a landscape-width column is taller than a short screen (landscape,
    // or the outer display of iPhone Duo) can spare above the keyboard.
    let height = verticalSizeClass == .compact ? min(maxW * 3 / 4, 220) : maxW * 3 / 4

    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach($images) { $item in
          let pixelSize = item.image.size
          let aspect = pixelSize.height > 0 ? pixelSize.width / pixelSize.height : 16.0 / 9.0
          let fitWidth = height * aspect
          let clampedWidth = min(max(fitWidth, minW), maxW)
          // Compared rather than tested against `minW...maxW`, which traps while
          // the width is still unmeasured and `maxW` is below `minW`.
          let shouldFill = fitWidth < minW || fitWidth > maxW

          Image(uiImage: item.image)
            .resizable()
            .aspectRatio(contentMode: shouldFill ? .fill : .fit)
            .frame(width: clampedWidth, height: height)
            .clipped()
            .clipShape(.rect(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
              Button(String(localized: "Toggle Spoiler", bundle: .module), systemImage: item.spoiler ? "eye.slash" : "eye") {
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
    // Not `measureWidth`: its preference never reported while the strip was still zero high.
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { parentWidth = $0 }
  }
}
