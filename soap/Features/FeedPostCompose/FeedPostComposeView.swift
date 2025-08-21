//
//  FeedPostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI
import PhotosUI

struct FeedPostComposeView: View {
  @State private var viewModel: FeedPostComposeViewModelProtocol = FeedPostComposeViewModel()
  @Environment(\.dismiss) private var dismiss

  @State private var showPhotosPicker: Bool = false
  @State private var isUploading: Bool = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          header
            .padding(.horizontal)
            .disabled(isUploading)

          TextField("What's happening?", text: $viewModel.text, axis: .vertical)
            .submitLabel(.return)
            .writingToolsBehavior(.complete)
            .padding(.horizontal)
            .disabled(isUploading)

          HStack {
            Spacer()

            Text("\(viewModel.text.count)/280")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal)

          if !viewModel.selectedImages.isEmpty {
            FeedPostPhotoItemStrip(images: $viewModel.selectedImages)
              .disabled(isUploading)
          }
        }
        .padding(.vertical)
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle("Write")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") {
            dismiss()
          }
          .disabled(isUploading)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(
            role: .confirm,
            action: {
              Task {
                isUploading = true
                defer { isUploading = false }
                do {
                  try await viewModel.writePost()
                  dismiss()
                } catch {
                  // TODO: Handle Error here
                }
              }
            }, label: {
              if isUploading {
                ProgressView()
                  .tint(.white)
              } else {
                Label("Done", systemImage: "arrow.up")
              }
            }
          )
          .disabled(viewModel.text.isEmpty)
          .disabled(viewModel.text.count > 280)
          .disabled(isUploading)
        }
      }
      .toolbar {
        ToolbarSpacer(.flexible, placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
          Button("Photo Library", systemImage: "photo.on.rectangle") {
            showPhotosPicker = true
          }
          .disabled(isUploading)
        }
      }
    }
    .task {
      await viewModel.fetchFeedUser()
    }
    .photosPicker(
      isPresented: $showPhotosPicker,
      selection: $viewModel.selectedItems,
      maxSelectionCount: 10,
      selectionBehavior: .ordered,
      matching: .images,
      photoLibrary: .shared()
    )
  }

  var header: some View {
    HStack {
      profileImage

      Picker(selection: $viewModel.selectedComposeType, label: EmptyView()) {
        Text(viewModel.feedUser?.nickname ?? "")
          .tag(FeedPostComposeViewModel.ComposeType.publicly)

        Text("Anonymously")
          .tag(FeedPostComposeViewModel.ComposeType.anonymously)
      }
      .pickerStyle(.menu)
      .tint(.primary)
      .buttonStyle(.glass)

      Spacer()
    }
  }

  @ViewBuilder
  var profileImage: some View {
    switch viewModel.selectedComposeType {
    case .publicly:
      if let url = viewModel.feedUser?.profileImageURL {
        LazyImage(url: url) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Circle()
              .fill(Color.secondarySystemBackground)
          }
        }
        .frame(width: 24, height: 24)
        .clipShape(.circle)
      } else {
        Circle()
          .fill(Color.secondarySystemBackground)
          .frame(width: 24, height: 24)
          .overlay {
            Text("😀")
              .font(.caption)
          }
      }
    case .anonymously:
      Circle()
        .fill(Color.secondarySystemBackground)
        .frame(width: 24, height: 24)
        .overlay {
          Text("😀")
            .font(.caption)
        }
    }
  }
}

#Preview {
  FeedPostComposeView()
}
