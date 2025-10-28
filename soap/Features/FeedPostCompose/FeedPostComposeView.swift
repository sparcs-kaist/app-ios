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
  @Environment(\.openURL) private var openURL

  @State private var showPhotosPicker: Bool = false
  @State private var isUploading: Bool = false
  
  @State private var showAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""
  
  @FocusState private var isFocused: Bool

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
            .focused($isFocused)

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
                  viewModel.handleException(error)
                  showAlert(title: String(localized: "Error"), message: String(localized: "An unexpected error occurred while uploading a post. Please try again later."))
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
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("Photo Library", systemImage: "photo.on.rectangle") {
            showPhotosPicker = true
          }
          .disabled(isUploading)
        }
      }
    }
    .alert(alertTitle, isPresented: $showAlert, actions: {
      Button("Okay") { }
    }, message: {
      Text(alertMessage)
    })
    .task {
      await viewModel.fetchFeedUser()
    }
    .onAppear {
      isFocused = true
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

        Text("Anonymous")
          .tag(FeedPostComposeViewModel.ComposeType.anonymously)
      }
      .pickerStyle(.menu)
      .tint(.primary)
      .buttonStyle(.glass)

      Spacer()
      
      Button {
        openURL(Constants.termsOfUseURL)
      } label: {
        Text("terms of use")
          .underline()
      }
      .tint(.secondary)
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
  
  private func showAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showAlert = true
  }
}

#Preview {
  FeedPostComposeView()
}
