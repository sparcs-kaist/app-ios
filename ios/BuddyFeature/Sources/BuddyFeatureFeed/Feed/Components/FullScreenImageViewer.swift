//
//  FullScreenImageViewer.swift
//  soap
//
//  Created by 하정우 on 5/4/26.
//

import SwiftUI
import NukeUI

struct FullScreenImageViewer: View {
  let url: URL

  @Environment(\.dismiss) private var dismiss

  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero

  private let minScale: CGFloat = 1.0
  private let maxScale: CGFloat = 5.0

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      LazyImage(url: url) { state in
        if let image = state.image {
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
            .onTapGesture(count: 2) { handleDoubleTap() }
        } else if let error = state.error {
          ContentUnavailableView(error.localizedDescription, systemImage: "exclamationmark.triangle")
            .font(.largeTitle)
            .foregroundStyle(.white)
        } else {
          ProgressView()
            .tint(.white)
        }
      }
    }
    .overlay(alignment: .topTrailing) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.title)
          .foregroundStyle(.white, .black.opacity(0.4))
          .padding()
        }
    }
    .statusBarHidden()
  }

  private var magnifyGesture: some Gesture {
    MagnifyGesture()
      .onChanged { value in
        let newScale = lastScale * value.magnification
        scale = min(max(newScale, minScale), maxScale)
      }
      .onEnded { _ in
        lastScale = scale
        if scale <= minScale {
          withAnimation(.spring) {
            scale = minScale
            lastScale = minScale
            offset = .zero
            lastOffset = .zero
          }
        }
      }
  }

  private var panGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        guard scale > minScale else { return }
        offset = CGSize(
          width: lastOffset.width + value.translation.width,
          height: lastOffset.height + value.translation.height
        )
      }
      .onEnded { _ in
        lastOffset = offset
      }
  }

  private func handleDoubleTap() {
    withAnimation(.spring) {
      if scale > minScale {
        scale = minScale
        lastScale = minScale
        offset = .zero
        lastOffset = .zero
      } else {
        scale = 2.0
        lastScale = 2.0
      }
    }
  }
}
