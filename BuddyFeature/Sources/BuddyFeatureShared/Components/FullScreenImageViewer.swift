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
            ZoomableImage(
              url: url,
              screen: screen,
              isCurrent: index == selection,
              isZoomed: index == selection ? $isZoomed : .constant(false)
            ) { image in
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
        // A drag on a zoomed image pans it; paging along with it makes the image lag the finger.
        .scrollDisabled(isZoomed)
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
      .toolbarBackground(.hidden, for: .navigationBar, .bottomBar)
      .toolbar(dismissDrag == .zero ? .automatic : .hidden, for: .navigationBar, .bottomBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) {
            dismiss()
          }
        }
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
          Menu(String(localized: "More", bundle: .module), systemImage: "ellipsis") {
            if let image = currentImage {
              imageActions(for: image)
            }
          }
          .disabled(currentImage == nil)
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
///
/// Zooming and panning are a `UIScrollView`'s, as in Photos: it tracks the finger directly and
/// decelerates and bounces, where SwiftUI gestures updating state lag behind on a large image.
private struct ZoomableImage: View {
  let url: URL
  let screen: ScreenGeometry
  /// Whether this is the page showing; leaving it shows the image whole again.
  let isCurrent: Bool
  @Binding var isZoomed: Bool
  /// Reports the image once it has loaded.
  var onLoad: (UIImage) -> Void = { _ in }

  /// Where this page is on screen, to centre the image on the screen rather than the page.
  /// Its horizontal position is left at zero: it changes on every frame of a page swipe, and
  /// the image doesn't need it.
  @State private var pageFrame: CGRect = .zero

  var body: some View {
    LazyImage(url: url) { state in
      if let image = state.imageContainer?.image {
        ZoomingImageView(
          image: image,
          safeArea: screen.bounds.isEmpty ? CGRect(origin: .zero, size: pageFrame.size) : screen.safeArea,
          isCurrent: isCurrent,
          isZoomed: $isZoomed
        )
        .frame(width: screenSize.width, height: screenSize.height)
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
        onLoad(response.image)
      }
    }
    // Centred on the screen, whatever part of it the paging view gave this page. Horizontally
    // that is where the page rests, not where it is: its live position moves with a page swipe,
    // and following it would hold the image still while the page slides.
    .position(
      x: screen.bounds.isEmpty ? pageFrame.width / 2 : screen.bounds.midX,
      y: screen.bounds.isEmpty ? pageFrame.height / 2 : screen.bounds.midY - pageFrame.minY
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(.rect)
    .onGeometryChange(for: CGRect.self) {
      let frame = $0.frame(in: .named(ScreenGeometry.space))
      return CGRect(x: 0, y: frame.minY, width: frame.width, height: frame.height)
    } action: { pageFrame = $0 }
  }

  private var screenSize: CGSize {
    screen.bounds.isEmpty ? pageFrame.size : screen.bounds.size
  }
}

/// The image in a zooming scroll view the size of the screen.
private struct ZoomingImageView: UIViewRepresentable {
  let image: UIImage
  /// The safe area, in the view's own coordinates.
  let safeArea: CGRect
  let isCurrent: Bool
  @Binding var isZoomed: Bool

  func makeUIView(context: Context) -> ZoomingScrollView {
    ZoomingScrollView()
  }

  func updateUIView(_ view: ZoomingScrollView, context: Context) {
    view.image = image
    view.safeArea = safeArea
    view.onZoomChange = { isZoomed in
      // Reported from UIKit, possibly mid-update; the binding is set afterwards.
      Task { @MainActor in self.isZoomed = isZoomed }
    }
    if !isCurrent {
      view.showWhole()
    }
  }
}

private final class ZoomingScrollView: UIScrollView, UIScrollViewDelegate {
  var image: UIImage? {
    didSet {
      guard image !== oldValue else { return }
      imageView.image = image
      fittedSize = .zero
      setNeedsLayout()
    }
  }

  var safeArea: CGRect = .zero {
    didSet {
      guard safeArea != oldValue else { return }
      fittedSize = .zero
      setNeedsLayout()
    }
  }

  var onZoomChange: (Bool) -> Void = { _ in }

  private let imageView = UIImageView()
  /// The bounds the image was last fitted to.
  private var fittedSize: CGSize = .zero
  private var zoomScaleAtStart: CGFloat = 1
  private var reportedZoomed = false

  init() {
    super.init(frame: .zero)
    delegate = self
    contentInsetAdjustmentBehavior = .never
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    decelerationRate = .fast
    maximumZoomScale = 5
    addSubview(imageView)

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
    doubleTap.numberOfTapsRequired = 2
    addGestureRecognizer(doubleTap)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if bounds.size != fittedSize {
      fit()
    }
  }

  /// Sizes the image to fill the screen at a zoom scale of 1.
  private func fit() {
    guard let image, image.size.width > 0, image.size.height > 0,
          bounds.width > 0, bounds.height > 0 else { return }
    fittedSize = bounds.size
    zoomScale = 1
    let screenFit = min(bounds.width / image.size.width, bounds.height / image.size.height)
    imageView.frame = CGRect(x: 0, y: 0, width: image.size.width * screenFit, height: image.size.height * screenFit)
    contentSize = imageView.frame.size
    // As small as fits the safe area, and no smaller once let go.
    let safe = safeArea.isEmpty ? bounds : safeArea
    let safeFit = min(safe.width / image.size.width, safe.height / image.size.height)
    minimumZoomScale = min(safeFit / screenFit, 1)
    centre()
  }

  /// Back to the whole image filling the screen.
  func showWhole() {
    guard zoomScale != 1 else { return }
    setZoomScale(1, animated: false)
  }

  /// Centres an image smaller than the screen: on the screen at full size, moving to the centre
  /// of the safe area (off-centre when only one side has a bar) as it shrinks to fit inside it.
  private func centre() {
    let size = imageView.frame.size
    let safe = safeArea.isEmpty ? bounds : safeArea
    let shrinkRange = 1 - minimumZoomScale
    let progress = shrinkRange > 0 ? min(max((1 - zoomScale) / shrinkRange, 0), 1) : 0
    let midX = bounds.width / 2 + (safe.midX - bounds.width / 2) * progress
    let midY = bounds.height / 2 + (safe.midY - bounds.height / 2) * progress

    func inset(_ length: CGFloat, in available: CGFloat, around mid: CGFloat) -> (CGFloat, CGFloat) {
      guard length < available else { return (0, 0) }
      let leading = min(max(mid - length / 2, 0), available - length)
      return (leading, available - length - leading)
    }
    let (left, right) = inset(size.width, in: bounds.width, around: midX)
    let (top, bottom) = inset(size.height, in: bounds.height, around: midY)
    contentInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
  }

  @objc private func doubleTapped(_ recognizer: UITapGestureRecognizer) {
    if zoomScale != 1 {
      setZoomScale(1, animated: true)
    } else {
      // Twice the size, centred on where was tapped.
      let point = recognizer.location(in: imageView)
      let size = CGSize(width: bounds.width / 2, height: bounds.height / 2)
      zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                      width: size.width, height: size.height), animated: true)
    }
  }

  // MARK: - UIScrollViewDelegate

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageView
  }

  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    zoomScaleAtStart = zoomScale
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    centre()
    let isZoomed = zoomScale > 1.01
    if isZoomed != reportedZoomed {
      reportedZoomed = isZoomed
      onZoomChange(isZoomed)
    }
  }

  func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    // Smaller than the screen settles inside the safe area; growing from there, back to full.
    guard scale < 1, scale > minimumZoomScale else { return }
    setZoomScale(scale < zoomScaleAtStart ? minimumZoomScale : 1, animated: true)
  }
}

/// The screen the viewer covers and the safe area within it, in the paging view's space.
private nonisolated struct ScreenGeometry: Equatable, Sendable {
  static let space = "FullScreenImageViewer"

  var bounds: CGRect = .zero
  var safeArea: CGRect = .zero
}
