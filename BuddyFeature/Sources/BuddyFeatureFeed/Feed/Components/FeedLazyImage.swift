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
  @Environment(FeedImageAspects.self) private var imageAspects: FeedImageAspects?

  private let minWidth: CGFloat = 100
  private let placeholderAspect: CGFloat = 4.0 / 3.0

  /// `LazyImage` only starts loading in `onAppear`, so even a cached image is
  /// first laid out as its placeholder. Giving the placeholder the image's real
  /// shape, once known, means the row doesn't resize when the image appears.
  private var expectedAspect: CGFloat {
    imageAspects?.aspect(for: item) ?? placeholderAspect
  }

  var body: some View {
    LazyImage(url: item.url) { state in
      Group {
        if let swiftUIImage = state.image {
          // Try to get the real pixel size to decide fit vs fill
          let pixelSize = state.imageContainer?.image.size ?? .zero
          let aspect = pixelSize.height > 0 ? pixelSize.width / pixelSize.height : expectedAspect
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
          let size = fitSize(aspect: expectedAspect)
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
    .onCompletion { result in
      guard case .success(let response) = result else { return }
      imageAspects?.record(response.image.size, for: item)
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
