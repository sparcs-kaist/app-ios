//
//  PostImagesStrip.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI

struct PostImagesStrip: View {
  let images: [FeedImage]
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
        ForEach(images) { item in
          LazyImage(url: item.url) { state in
            Group {
              if let swiftUIImage = state.image {
                // Try to get the real pixel size to decide fit vs fill
                let pixelSize = state.imageContainer?.image.size ?? .zero
                let aspect = pixelSize.height > 0 ? pixelSize.width / pixelSize.height : 16.0 / 9.0
                let fitWidth = height * aspect
                let clampedWidth = min(max(fitWidth, minW), maxW)
                let shouldFill = !(minW...maxW).contains(fitWidth)

                swiftUIImage
                  .resizable()
                  .aspectRatio(contentMode: shouldFill ? .fill : .fit)
                  .frame(width: clampedWidth, height: height)
                  .clipped()
              } else if state.error != nil {
                Placeholder(width: minW, height: height, systemImage: "exclamationmark.triangle")
              } else {
                Placeholder(width: minW, height: height)
                  .redacted(reason: .placeholder)
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          }
        }
      }
      .padding(.horizontal, hPadding)
    }
    .frame(height: height)                 // fixes row height to 16:9 of parent width (minus padding)
    .measureWidth { parentWidth = $0 }     // read parent width
  }
}

private struct Placeholder: View {
  let width: CGFloat
  let height: CGFloat
  var systemImage: String? = nil

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(.secondary.opacity(0.12))
      if let systemImage {
        Image(systemName: systemImage)
          .font(.title2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: width, height: height)
  }
}
