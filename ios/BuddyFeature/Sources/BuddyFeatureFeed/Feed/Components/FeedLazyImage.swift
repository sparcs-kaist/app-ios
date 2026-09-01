//
//  FeedLazyImage.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import SwiftUI
import NukeUI
import BuddyDomain

struct FeedLazyImage: View {
  let item: FeedImage
  let maxWidth: CGFloat
  let maxHeight: CGFloat
  let onTap: () -> Void

  @Environment(SpoilerContents.self) private var spoilerContents

  private let minWidth: CGFloat = 100
  private let placeholderAspect: CGFloat = 4.0 / 3.0

  var body: some View {
    LazyImage(url: item.url) { state in
      Group {
        if let swiftUIImage = state.image {
          // Try to get the real pixel size to decide fit vs fill
          let pixelSize = state.imageContainer?.image.size ?? .zero
          let aspect = pixelSize.height > 0 ? pixelSize.width / pixelSize.height : placeholderAspect
          let cell = fitSize(aspect: aspect)
          let imageWidth = min(cell.width, cell.height * aspect)

          swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageWidth, height: cell.height)
            .background(Color(.systemBackground))
            .frame(width: cell.width, height: cell.height)
            .background(Color(.secondarySystemBackground))
        } else if state.error != nil {
          let size = fitSize(aspect: placeholderAspect)
          Placeholder(width: size.width, height: size.height, systemImage: "exclamationmark.triangle")
        } else {
          let size = fitSize(aspect: placeholderAspect)
          Placeholder(width: size.width, height: size.height)
            .redacted(reason: .placeholder)
        }
      }
      .overlay {
        if item.spoiler == true && !spoilerContents.contains(item.id) {
          Rectangle()
            .fill(.ultraThinMaterial)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .contentShape(.rect)
      .highPriorityGesture(
        TapGesture().onEnded {
          if item.spoiler == true && !spoilerContents.contains(item.id) {
            withAnimation(.easeInOut(duration: 0.3)) {
              spoilerContents.add(item.id)
            }
          } else {
            onTap()
          }
        }
      )
    }
  }

  private func fitSize(aspect: CGFloat) -> CGSize {
    let naturalHeight = maxWidth / aspect
    if naturalHeight <= maxHeight {
      return CGSize(width: maxWidth, height: naturalHeight)
    } else {
      let height = maxHeight
      let width = max(minWidth, height * aspect)
      return CGSize(width: width, height: height)
    }
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
