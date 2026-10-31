//
//  TaxiChatInputBar.swift
//  soap
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import SwiftUI
import PhotosUI
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiChatInputBar")

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

  @Environment(\.verticalSizeClass) private var verticalSizeClass

  var body: some View {
    HStack(alignment: .bottom) {
      Menu {
        Button(String(localized: "Send Payment", bundle: .module), systemImage: "wonsign.circle") {
          onShowPayMoneyAlert()
        }
        .disabled(!isCommitPaymentAvailable)
        Button(String(localized: "Request Settlement", bundle: .module), systemImage: "square.and.pencil") {
          onCommitSettlement()
        }
        .disabled(!isCommitSettlementAvailable)

        Button(String(localized: "Photo Library", bundle: .module), systemImage: "photo.on.rectangle") {
          showPhotosPicker = true
        }
      } label: {
        Label(String(localized: "More", bundle: .module), systemImage: "plus")
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
            // On a short screen a 200-point preview plus the keyboard would
            // leave almost no room for the conversation.
            .frame(maxHeight: verticalSizeClass == .compact ? 120 : 200)
            .clipShape(.containerRelative)
            .overlay(alignment: .topTrailing) {
              Button(String(localized: "Remove", bundle: .module), systemImage: "xmark") {
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
            String(localized: "Chat as \(nickname)", bundle: .module),
            text: $text,
            axis: .vertical
          )
            // Grow with the message, then scroll, so a long draft cannot push
            // the conversation off a short screen.
            .lineLimit(1...5)
            .padding(.leading, 4)
            .frame(minHeight: 32)
            .focused($isFocused)
        }

        Button(String(localized: "Send", bundle: .module), systemImage: "arrow.up") {
          if let image = selectedImage {
            Task {
              do {
                try await onSendImage(image)
                selectedItem = nil
                selectedImage = nil
              } catch {
                logger.error("Failed to send image: \(error.localizedDescription, privacy: .public)")
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
