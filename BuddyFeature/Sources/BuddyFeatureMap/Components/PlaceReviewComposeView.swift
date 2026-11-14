//
//  PlaceReviewComposeView.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 14/11/2026.
//

import SwiftUI
import PhotosUI
import BuddyDomain

/// The sheet for reviewing a place: stars to tap, room for a few words, then photos picked from
/// the library or taken on the spot. Stars are required; words and photos are not.
struct PlaceReviewComposeView: View {
  /// As many photos as one review carries.
  private static let photoLimit = 5

  let placeName: String
  /// Stars, 1...5, the text, which may be empty, and the photos to attach.
  let onSubmit: (Int, String, [PlacePhoto]) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var rating: Int
  @State private var text: String
  @State private var photos: [PlacePhoto]

  @State private var pickedItems: [PhotosPickerItem] = []
  @State private var showsLibrary = false
  @State private var showsCamera = false
  @State private var isLoadingPhotos = false

  private var remainingPhotos: Int {
    Self.photoLimit - photos.count
  }

  /// `rating`, `text` and `photos` are what the user gave before, to carry on from; 0 and empty
  /// for a first review.
  init(
    placeName: String,
    rating: Int = 0,
    text: String = "",
    photos: [PlacePhoto] = [],
    onSubmit: @escaping (Int, String, [PlacePhoto]) -> Void
  ) {
    self.placeName = placeName
    self.onSubmit = onSubmit
    self._rating = State(initialValue: rating)
    self._text = State(initialValue: text)
    self._photos = State(initialValue: photos)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          VStack(spacing: 8) {
            StarRatingPicker(rating: $rating)
            Text(rating == 0 ? "Tap to Rate" : "\(rating) out of 5 stars", bundle: .module)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .contentTransition(.numericText(value: Double(rating)))
              .animation(.snappy, value: rating)
              .accessibilityHidden(true)
          }
          .frame(maxWidth: .infinity)

          TextField(
            "",
            text: $text,
            prompt: Text("Share your thoughts on \(placeName)...", bundle: .module),
            axis: .vertical
          )
          .lineLimit(4...)
          .padding(14)
          .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))

          photoRow
        }
        .padding()
        .contentWidth()
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(String(localized: "Write a Review", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .close) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(role: .confirm) {
            onSubmit(rating, text, photos)
            dismiss()
          } label: {
            Label(String(localized: "Done", bundle: .module), systemImage: "arrow.up")
          }
          .disabled(rating == 0 || isLoadingPhotos)
        }
      }
      .photosPicker(
        isPresented: $showsLibrary,
        selection: $pickedItems,
        maxSelectionCount: max(remainingPhotos, 1),
        matching: .images
      )
      .onChange(of: pickedItems) {
        guard !pickedItems.isEmpty else { return }
        let items = pickedItems
        pickedItems = []
        Task { await attach(items) }
      }
      .fullScreenCover(isPresented: $showsCamera) {
        CameraPicker { image in
          attach(image)
        }
        .ignoresSafeArea()
      }
    }
  }

  // MARK: - Photos

  /// The attached photos, each with a button to take it off, then the tile that adds more.
  private var photoRow: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(photos) { photo in
          PlacePhotoView(photo: photo, category: .building)
            .frame(width: 84, height: 84)
            .clipShape(.rect(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topTrailing) {
              Button {
                withAnimation(.snappy) { photos.removeAll { $0.id == photo.id } }
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .font(.title3)
                  .symbolRenderingMode(.palette)
                  .foregroundStyle(.white, .black.opacity(0.6))
                  .padding(4)
              }
              .buttonStyle(.plain)
              .accessibilityLabel(Text("Remove Photo", bundle: .module))
            }
        }

        if remainingPhotos > 0 {
          Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
              Button(String(localized: "Take Photo", bundle: .module), systemImage: "camera") {
                showsCamera = true
              }
            }
            Button(String(localized: "Choose from Library", bundle: .module), systemImage: "photo.on.rectangle") {
              showsLibrary = true
            }
          } label: {
            VStack(spacing: 4) {
              if isLoadingPhotos {
                ProgressView()
              } else {
                Image(systemName: "camera.fill")
                  .font(.title3)
              }
              Text("Add Photo", bundle: .module)
                .font(.caption2.weight(.semibold))
            }
            .frame(width: 84, height: 84)
            .background(.fill.quaternary, in: .rect(cornerRadius: 12, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.tint.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
            }
          }
          .disabled(isLoadingPhotos)
        }
      }
    }
    .scrollIndicators(.hidden)
    .scrollClipDisabled()
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Loads what was picked from the library, in the order picked, up to the limit.
  private func attach(_ items: [PhotosPickerItem]) async {
    isLoadingPhotos = true
    defer { isLoadingPhotos = false }
    for item in items.prefix(remainingPhotos) {
      guard let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data) else { continue }
      attach(image)
    }
  }

  /// Scales the image down, writes it to a temporary file and attaches it. The file is what the
  /// review points at until there is an API to upload to.
  private func attach(_ image: UIImage) {
    guard remainingPhotos > 0 else { return }
    let side: CGFloat = 1600
    let scale = min(1, side / max(image.size.width, image.size.height))
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
    let id = UUID().uuidString
    let url = FileManager.default.temporaryDirectory.appending(path: "review-\(id).jpg")
    guard let data = resized.jpegData(compressionQuality: 0.8), (try? data.write(to: url)) != nil else { return }
    withAnimation(.snappy) { photos.append(PlacePhoto(id: id, url: url)) }
  }
}

/// The system camera, for taking one photo. Hands the photo back and closes itself.
private struct CameraPicker: UIViewControllerRepresentable {
  let onCapture: (UIImage) -> Void

  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onCapture: onCapture, dismiss: dismiss)
  }

  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let onCapture: (UIImage) -> Void
    private let dismiss: DismissAction

    init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
      self.onCapture = onCapture
      self.dismiss = dismiss
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage {
        onCapture(image)
      }
      dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss()
    }
  }
}

#Preview {
  PlaceReviewComposeView(placeName: "Kaimaru", onSubmit: { _, _, _ in })
}
