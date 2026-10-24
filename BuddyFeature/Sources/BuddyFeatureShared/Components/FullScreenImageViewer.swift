//
//  FullScreenImageViewer.swift
//  soap
//
//  Created by 하정우 on 5/4/26.
//

import SwiftUI
import NukeUI

/// A set of images to show full screen, opened at one of them.
public struct ImageGallery: Identifiable, Hashable, Sendable {
  public let urls: [URL]
  public let initialIndex: Int

  public var id: Self { self }

  public init(urls: [URL], initialIndex: Int = 0) {
    self.urls = urls
    self.initialIndex = min(max(initialIndex, 0), max(urls.count - 1, 0))
  }

  /// The gallery of `urls` opened at `url`, or `nil` when `url` isn't among them.
  public init?(urls: [URL], selected url: URL) {
    guard let index = urls.firstIndex(of: url) else { return nil }
    self.init(urls: urls, initialIndex: index)
  }
}

/// Full-screen images on black: swipe between them, pinch or double-tap to zoom.
/// Present it with `fullScreenCover(item:)` and an ``ImageGallery``.
///
/// With a `transitionNamespace`, it zooms out of the thumbnail marked
/// `.matchedTransitionSource(id: url, in: namespace)` and can be swiped down to dismiss,
/// zooming back into the thumbnail of whichever image is showing. `onPageChange` lets the
/// screen behind scroll that thumbnail into view, so the zoom back has somewhere to land.
public struct FullScreenImageViewer: View {
  let gallery: ImageGallery
  let transitionNamespace: Namespace.ID?
  let onPageChange: ((URL) -> Void)?

  @Environment(\.dismiss) private var dismiss
  @State private var selection: Int
  /// Whether the image showing is zoomed in; a drag then pans it instead of dismissing.
  @State private var isZoomed = false
  @State private var dismissDrag: CGSize = .zero
  /// Decided at the start of each drag, so a horizontal page swipe never moves the image down.
  @State private var isDismissDrag: Bool?

  /// How far a swipe down has to go, in points, to dismiss rather than spring back.
  private let dismissDistance: CGFloat = 120

  public init(
    gallery: ImageGallery,
    transitionNamespace: Namespace.ID? = nil,
    onPageChange: ((URL) -> Void)? = nil
  ) {
    self.gallery = gallery
    self.transitionNamespace = transitionNamespace
    self.onPageChange = onPageChange
    self._selection = State(initialValue: gallery.initialIndex)
  }

  public var body: some View {
    NavigationStack {
      TabView(selection: $selection) {
        ForEach(Array(gallery.urls.enumerated()), id: \.offset) { index, url in
          ZoomableImage(url: url, isZoomed: index == selection ? $isZoomed : .constant(false))
            .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: gallery.urls.count > 1 && dismissDrag == .zero ? .automatic : .never))
      // Follows the finger and shrinks a little on the way down, as in Photos.
      .scaleEffect(1 - min(max(dismissDrag.height, 0) / 1500, 0.25))
      .offset(dismissDrag)
      .simultaneousGesture(dismissGesture, including: isZoomed ? .subviews : .all)
      // A page reset when left only reports it through its old binding.
      .onChange(of: selection) { _, selection in
        isZoomed = false
        if gallery.urls.indices.contains(selection) {
          onPageChange?(gallery.urls[selection])
        }
      }
      .background(Color.black.opacity(backdropOpacity))
      .ignoresSafeArea()
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar(dismissDrag == .zero ? .automatic : .hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) {
            dismiss()
          }
        }
      }
    }
    // Light glass and title on the black backdrop.
    .environment(\.colorScheme, .dark)
    // The screen behind shows through as the backdrop fades during a swipe down.
    .presentationBackground(.clear)
    .modifier(ZoomTransition(sourceID: gallery.urls.indices.contains(selection) ? gallery.urls[selection] : nil,
                             namespace: transitionNamespace))
  }

  private var backdropOpacity: Double {
    1 - min(Double(max(dismissDrag.height, 0) / 400), 0.8)
  }

  private var dismissGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { value in
        if isDismissDrag == nil {
          let translation = value.translation
          isDismissDrag = translation.height > 0 && translation.height > abs(translation.width)
        }
        guard isDismissDrag == true else { return }
        dismissDrag = value.translation
      }
      .onEnded { value in
        defer { isDismissDrag = nil }
        guard isDismissDrag == true else { return }
        if value.translation.height > dismissDistance || value.predictedEndTranslation.height > dismissDistance * 3 {
          dismiss()
        } else {
          withAnimation(.spring(duration: 0.3)) { dismissDrag = .zero }
        }
      }
  }

  private var title: String {
    guard gallery.urls.count > 1 else { return "" }
    return String(localized: "\(selection + 1) of \(gallery.urls.count)", bundle: .module)
  }
}

private struct ZoomTransition: ViewModifier {
  let sourceID: URL?
  let namespace: Namespace.ID?

  func body(content: Content) -> some View {
    if let sourceID, let namespace {
      content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
    } else {
      content
    }
  }
}

/// One page: an image that zooms with a pinch or double tap and pans while zoomed.
private struct ZoomableImage: View {
  let url: URL
  @Binding var isZoomed: Bool

  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero

  private let minScale: CGFloat = 1.0
  private let maxScale: CGFloat = 5.0


  var body: some View {
    LazyImage(url: url) { state in
      if let image = state.image {
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(scale)
          .offset(offset)
          .gesture(magnifyGesture)
          // Panning only takes over while zoomed; otherwise the drag pages to the next image.
          .gesture(panGesture, including: isZoomed ? .all : .subviews)
          .onTapGesture(count: 2) { handleDoubleTap() }
      } else if let error = state.error {
        ContentUnavailableView(error.localizedDescription, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.white)
      } else {
        ProgressView()
          .tint(.white)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(.rect)
    // Swiping back to this page shows it whole again.
    .onDisappear(perform: resetZoom)
    .onChange(of: scale) { _, scale in
      isZoomed = scale > minScale
    }
  }

  private var magnifyGesture: some Gesture {
    MagnifyGesture()
      .onChanged { value in
        scale = min(max(lastScale * value.magnification, minScale), maxScale)
      }
      .onEnded { _ in
        lastScale = scale
        if scale <= minScale {
          withAnimation(.spring) { resetZoom() }
        }
      }
  }

  private var panGesture: some Gesture {
    DragGesture()
      .onChanged { value in
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
      if isZoomed {
        resetZoom()
      } else {
        scale = 2.0
        lastScale = 2.0
      }
    }
  }

  private func resetZoom() {
    scale = minScale
    lastScale = minScale
    offset = .zero
    lastOffset = .zero
  }
}
