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
  
  var body: some View {
    LazyImage(url: item.url) { state in
      Group {
        if let swiftUIImage = state.image {
          swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: cell.width, height: cell.height)
            .clipped()
            .background(Color(.secondarySystemBackground))
        } else if state.error != nil {
          Placeholder(width: cell.width, height: cell.height, systemImage: "exclamationmark.triangle")
        } else {
          Placeholder(width: cell.width, height: cell.height)
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
  
  private var cell: CGSize {
    CGSize(width: maxWidth, height: maxHeight)
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
