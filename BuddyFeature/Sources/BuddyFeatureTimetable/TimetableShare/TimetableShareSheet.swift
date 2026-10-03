//
//  TimetableShareSheet.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 03/10/2026.
//

import SwiftUI
import Photos
import BuddyDomain
import BuddyFeatureShared

/// Offered after a screenshot of the timetable: the timetable as its share image, with ways to
/// send it on.
struct TimetableShareSheet: View {
  let item: TimetableShareImage

  @State private var showsActivitySheet = false
  @State private var saveState: SaveState = .idle
  @State private var showsSaveError = false
  @State private var isInstagramAvailable = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      content
        .navigationTitle(String(localized: "Share \"\(item.name)\"", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button(String(localized: "Close", bundle: .module), systemImage: "xmark", role: .close) {
              dismiss()
            }
          }
        }
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
    .sheet(isPresented: $showsActivitySheet) {
      ActivityView(
        activityItems: [item.source],
        applicationActivities: [InstagramStoryActivity(
          appID: Constants.metaAppID,
          backgroundColorHex: item.backgroundColorHex
        )]
      )
    }
    .alert(String(localized: "Unable to Save", bundle: .module), isPresented: $showsSaveError) {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    } message: {
      Text("Allow Buddy to add photos in Settings, then try again.", bundle: .module)
    }
    .onAppear {
      isInstagramAvailable = InstagramStory.isAvailable(appID: Constants.metaAppID)
    }
  }

  private var content: some View {
    VStack(spacing: 20) {
      Image(uiImage: item.source.image)
        .resizable()
        .scaledToFit()
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 8)
        .accessibilityLabel(Text("Timetable Image", bundle: .module))

      actions
    }
    .padding(.bottom, 8)
  }

  private var actions: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: 20) {
        ShareActionButton(
          title: String(localized: "Share", bundle: .module),
          systemImage: "square.and.arrow.up"
        ) {
          showsActivitySheet = true
        }

        ShareActionButton(
          title: saveState == .saved
            ? String(localized: "Saved", bundle: .module)
            : String(localized: "Save to Photos", bundle: .module),
          systemImage: saveState == .saved ? "checkmark" : "square.and.arrow.down"
        ) {
          Task { await saveToPhotos() }
        }
        .disabled(saveState != .idle)
        .sensoryFeedback(.success, trigger: saveState == .saved)

        if isInstagramAvailable {
          ShareActionButton(
            title: String(localized: "Instagram Story", bundle: .module),
            systemImage: "camera"
          ) {
            Task { await shareToInstagramStory() }
          }
        }
      }
      .padding(.horizontal, 24)
      // Centred while the buttons fit, scrolling once they do not.
      .containerRelativeFrame(.horizontal, alignment: .center) { width, _ in width }
    }
    .scrollIndicators(.hidden)
    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
  }

  private func saveToPhotos() async {
    saveState = .saving
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else {
      saveState = .idle
      showsSaveError = true
      return
    }
    let image = item.source.image
    do {
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }
      withAnimation(.snappy) { saveState = .saved }
    } catch {
      saveState = .idle
      showsSaveError = true
    }
  }

  private func shareToInstagramStory() async {
    guard let stickerData = item.source.instagramStoryImage.pngData() else { return }
    await InstagramStory.share(
      stickerData: stickerData,
      backgroundColorHex: item.backgroundColorHex,
      appID: Constants.metaAppID
    )
  }

  private enum SaveState {
    case idle, saving, saved
  }
}

/// A round button with its name underneath, as in the system share sheet.
private struct ShareActionButton: View {
  let title: String
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Image(systemName: systemImage)
          .font(.title2)
          .contentTransition(.symbolEffect(.replace))
          .frame(width: 60, height: 60)
          .glassEffect(.regular.interactive(), in: .circle)
        // Full strength rather than secondary, which is faint over the sheet's glass.
        Text(title)
          .font(.footnote.weight(.medium))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
          .frame(width: 84)
      }
    }
    .buttonStyle(.plain)
  }
}
