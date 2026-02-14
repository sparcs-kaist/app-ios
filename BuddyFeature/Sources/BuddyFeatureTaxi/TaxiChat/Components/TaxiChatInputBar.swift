//
//  TaxiChatInputBar.swift
//  soap
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import SwiftUI
import PhotosUI

struct TaxiChatInputBar: View {
  @Binding var text: String
  let nickname: String
  let isUploading: Bool
  let isCommitPaymentAvailable: Bool
  let isCommitSettlementAvailable: Bool

  var onSendText: (String) -> Void
  var onSendImage: (UIImage) async throws -> Void
  var onCommitSettlement: () -> Void
  var onShowPayMoneyAlert: () -> Void
  var onError: (String) -> Void

  @State private var showPhotosPicker: Bool = false
  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImage: UIImage?
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(alignment: .bottom) {
      Menu {
        Button("Send Payment", systemImage: "wonsign.circle") {
          onShowPayMoneyAlert()
        }
        .disabled(!isCommitPaymentAvailable)
        Button("Request Settlement", systemImage: "square.and.pencil") {
          onCommitSettlement()
        }
        .disabled(!isCommitSettlementAvailable)

        Button("Photo Library", systemImage: "photo.on.rectangle") {
          showPhotosPicker = true
        }
      } label: {
        Label("More", systemImage: "plus")
          .labelStyle(.iconOnly)
          .fontWeight(.semibold)
          .frame(width: 48, height: 48)
          .contentShape(.circle)
      }
      .glassEffect(.regular.interactive(), in: .circle)

      HStack(alignment: .bottom) {
        if let image = selectedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 200)
            .clipShape(.containerRelative)
            .overlay(alignment: .topTrailing) {
              Button("Remove", systemImage: "xmark") {
                selectedItem = nil
                selectedImage = nil
              }
              .labelStyle(.iconOnly)
              .padding(4)
              .font(.caption2)
              .glassEffect(.regular.interactive(), in: .circle)
              .padding(8)
            }

          Spacer()
        } else {
          TextField(
            "Chat as \(nickname)",
            text: $text,
            axis: .vertical
          )
            .padding(.leading, 4)
            .frame(minHeight: 32)
            .focused($isFocused)
        }

        Button("Send", systemImage: "arrow.up") {
          if let image = selectedImage {
            Task {
              do {
                try await onSendImage(image)
                selectedItem = nil
                selectedImage = nil
              } catch {
                onError(error.localizedDescription)
              }
            }
          } else {
            onSendText(text)
            text = ""
          }
        }
        .labelStyle(.iconOnly)
        .fontWeight(.semibold)
        .buttonStyle(.borderedProminent)
        .frame(height: 32)
        .opacity((text.isEmpty && selectedImage == nil) ? 0 : 1)
        .disabled((text.isEmpty && selectedImage == nil) || isUploading)
        .overlay {
          if isUploading {
            ProgressView()
          }
        }
      }
      .padding(8)
      .frame(maxWidth: .infinity)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
    }
    .padding(isFocused ? [.horizontal, .vertical] : [.horizontal])
    .photosPicker(
      isPresented: $showPhotosPicker,
      selection: $selectedItem,
      matching: .images,
      photoLibrary: .shared()
    )
    .onChange(of: selectedItem) {
      Task {
        guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
        guard let image = UIImage(data: imageData) else { return }
        self.selectedImage = image
      }
    }
  }
}
