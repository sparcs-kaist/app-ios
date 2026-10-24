//
//  FullScreenImageViewer.swift
//  soap
//
//  Created by 하정우 on 5/4/26.
//

import SwiftUI
import NukeUI
import Photos

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

  /// Images loaded so far, for sharing, saving and copying the one showing.
  @State private var loadedImages: [URL: UIImage] = [:]
  @State private var toast: ImageActionToast?
  /// The screen (the paging view, at rest) and the safe area within it, in global coordinates.
  @State private var screenFrame: CGRect = .zero
  @State private var safeAreaFrame: CGRect = .zero
  @State private var saveErrorMessage: String?

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
      ZStack {
        // The pages ignore the safe area, so this tells them where it is.
        Color.clear
          .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { safeAreaFrame = $0 }
        TabView(selection: $selection) {
          ForEach(Array(gallery.urls.enumerated()), id: \.offset) { index, url in
            ZoomableImage(url: url, screen: screen, isZoomed: index == selection ? $isZoomed : .constant(false)) { image in
              loadedImages[url] = image
            }
            .contextMenu {
              if let image = loadedImages[url] {
                imageActions(for: image)
              }
            }
            .tag(index)
            .scrollEdgeEffectHidden()
          }
        }
        // Pages place their image in this space, so it still moves with a swipe down.
        .coordinateSpace(.named(ScreenGeometry.space))
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
          // Mid-swipe the frame includes the swipe's transform; the screen hasn't changed.
          if dismissDrag == .zero { screenFrame = frame }
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
        // The bars float over the image; nothing dims it behind them.
        .scrollEdgeEffectHidden()
        .background(Color.black.opacity(backdropOpacity))
        .ignoresSafeArea()
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar(dismissDrag == .zero ? .automatic : .hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Menu(String(localized: "More", bundle: .module), systemImage: "ellipsis") {
            if let image = currentImage {
              imageActions(for: image)
            }
          }
          .disabled(currentImage == nil)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) {
            dismiss()
          }
        }
      }
      .overlay(alignment: .bottom) {
        if let toast {
          Label(toast.title, systemImage: toast.systemImage)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
            .padding(.bottom, 48)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .alert(
        String(localized: "Unable to Save Photo", bundle: .module),
        isPresented: Binding(get: { saveErrorMessage != nil }, set: { if !$0 { saveErrorMessage = nil } })
      ) {
        Button(String(localized: "OK", bundle: .module), role: .cancel) {}
      } message: {
        Text(saveErrorMessage ?? "")
      }
    }
    // Light glass and title on the black backdrop.
    .environment(\.colorScheme, .dark)
    // The screen behind shows through as the backdrop fades during a swipe down.
    .presentationBackground(.clear)
    // A pinch belongs to the image (smaller settles it in the safe area); the zoom transition
    // would otherwise take it as pinch-to-close. The swipe down above still dismisses.
    .interactiveDismissDisabled()
    .modifier(ZoomTransition(sourceID: gallery.urls.indices.contains(selection) ? gallery.urls[selection] : nil,
                             namespace: transitionNamespace))
  }

  // MARK: - Image actions

  private var currentImage: UIImage? {
    gallery.urls.indices.contains(selection) ? loadedImages[gallery.urls[selection]] : nil
  }

  @ViewBuilder
  private func imageActions(for image: UIImage) -> some View {
    ShareLink(
      item: Image(uiImage: image),
      preview: SharePreview(String(localized: "Photo", bundle: .module), image: Image(uiImage: image))
    ) {
      Label(String(localized: "Share", bundle: .module), systemImage: "square.and.arrow.up")
    }
    Button(String(localized: "Save to Photos", bundle: .module), systemImage: "square.and.arrow.down") {
      Task { await save(image) }
    }
    Button(String(localized: "Copy", bundle: .module), systemImage: "doc.on.doc") {
      UIPasteboard.general.image = image
      show(.copied)
    }
  }

  private func save(_ image: UIImage) async {
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else {
      saveErrorMessage = String(localized: "Allow Buddy to add photos in Settings, then try again.", bundle: .module)
      return
    }
    do {
      try await Self.addToPhotoLibrary(image)
      show(.saved)
    } catch {
      saveErrorMessage = error.localizedDescription
    }
  }

  /// `nonisolated` so the change block isn't inferred as main-actor: Photos runs it on its own
  /// queue, and a main-actor closure traps there.
  private nonisolated static func addToPhotoLibrary(_ image: UIImage) async throws {
    try await PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.creationRequestForAsset(from: image)
    }
  }

  private func show(_ newToast: ImageActionToast) {
    withAnimation(.snappy) { toast = newToast }
    Task {
      try? await Task.sleep(for: .seconds(1.5))
      guard toast == newToast else { return }
      withAnimation(.snappy) { toast = nil }
    }
  }

  /// The screen and its safe area, relative to the paging view.
  private var screen: ScreenGeometry {
    ScreenGeometry(
      bounds: CGRect(origin: .zero, size: screenFrame.size),
      safeArea: safeAreaFrame.offsetBy(dx: -screenFrame.minX, dy: -screenFrame.minY)
    )
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

/// A brief confirmation after an image action.
private enum ImageActionToast: Equatable {
  case saved, copied

  var title: String {
    switch self {
    case .saved: String(localized: "Saved to Photos", bundle: .module)
    case .copied: String(localized: "Copied", bundle: .module)
    }
  }

  var systemImage: String {
    switch self {
    case .saved: "checkmark.circle.fill"
    case .copied: "doc.on.doc.fill"
    }
  }
}

/// One page: an image that zooms with a pinch or double tap and pans while zoomed.
///
/// It fills the whole screen, safe area included. Pinching it smaller settles it inside the
/// safe area instead, clear of the bars (on iPhone Duo, the one down the side).
private struct ZoomableImage: View {
  let url: URL
  let screen: ScreenGeometry
  @Binding var isZoomed: Bool
  /// Reports the image once it has loaded.
  var onLoad: (UIImage) -> Void = { _ in }

  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero
  @State private var imageSize: CGSize?
  /// Where this page is on screen, to centre the image on the screen rather than the page.
  @State private var pageFrame: CGRect = .zero

  private let maxScale: CGFloat = 5.0

  var body: some View {
    LazyImage(url: url) { state in
      if let image = state.image {
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: screenSize.width, height: screenSize.height)
          .scaleEffect(scale)
          .offset(offset)
          .gesture(magnifyGesture)
          // Panning only takes over while zoomed; otherwise the drag pages to the next image.
          .gesture(panGesture, including: isZoomed ? .all : .subviews)
          .onTapGesture(count: 2) { handleDoubleTap() }
          .onAppear { imageSize = state.imageContainer?.image.size }
      } else if let error = state.error {
        ContentUnavailableView(error.localizedDescription, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.white)
      } else {
        ProgressView()
          .tint(.white)
      }
    }
    .onCompletion { result in
      if case .success(let response) = result {
        imageSize = response.image.size
        onLoad(response.image)
      }
    }
    // Centred on the screen, whatever part of it the paging view gave this page.
    .position(
      x: screen.bounds.isEmpty ? pageFrame.width / 2 : screen.bounds.midX - pageFrame.minX,
      y: screen.bounds.isEmpty ? pageFrame.height / 2 : screen.bounds.midY - pageFrame.minY
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(.rect)
    .onGeometryChange(for: CGRect.self) {
      $0.frame(in: .named(ScreenGeometry.space))
    } action: { pageFrame = $0 }
    // Swiping back to this page shows it whole again.
    .onDisappear(perform: resetZoom)
    .onChange(of: scale) { _, scale in
      isZoomed = scale > 1
    }
  }

  private var screenSize: CGSize {
    screen.bounds.isEmpty ? pageFrame.size : screen.bounds.size
  }

  /// The scale and offset that fit the image inside the safe area rather than the whole screen.
  private var safeAreaFit: (scale: CGFloat, offset: CGSize) {
    let full = screen.bounds, safe = screen.safeArea
    guard let imageSize, imageSize.width > 0, imageSize.height > 0,
          !full.isEmpty, !safe.isEmpty else { return (1, .zero) }
    let screenFit = min(full.width / imageSize.width, full.height / imageSize.height)
    let safeFit = min(safe.width / imageSize.width, safe.height / imageSize.height)
    return (
      min(safeFit / screenFit, 1),
      // Centred in the safe area, which is off-centre when only one side has a bar.
      CGSize(width: safe.midX - full.midX, height: safe.midY - full.midY)
    )
  }

  private var magnifyGesture: some Gesture {
    MagnifyGesture()
      .onChanged { value in
        scale = min(max(lastScale * value.magnification, safeAreaFit.scale * 0.8), maxScale)
      }
      .onEnded { _ in
        if scale <= 1 {
          // Smaller than the screen settles inside the safe area; growing from there, back to full.
          let isShrinking = scale < lastScale
          withAnimation(.spring) { isShrinking ? fitToSafeArea() : resetZoom() }
        } else {
          lastScale = scale
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
      if scale != 1 {
        resetZoom()
      } else {
        scale = 2.0
        lastScale = 2.0
      }
    }
  }

  private func resetZoom() {
    scale = 1
    lastScale = 1
    offset = .zero
    lastOffset = .zero
  }

  private func fitToSafeArea() {
    let fit = safeAreaFit
    scale = fit.scale
    lastScale = fit.scale
    offset = fit.offset
    lastOffset = fit.offset
  }
}

/// The screen the viewer covers and the safe area within it, in the paging view's space.
private nonisolated struct ScreenGeometry: Equatable, Sendable {
  static let space = "FullScreenImageViewer"

  var bounds: CGRect = .zero
  var safeArea: CGRect = .zero
}
