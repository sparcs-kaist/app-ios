//
//  FeedPostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import Foundation
import SwiftUI
import NukeUI
import PhotosUI
import BuddyDomain
import FirebaseAnalytics

struct FeedPostComposeView: View {
  @State private var viewModel: FeedPostComposeViewModelProtocol = FeedPostComposeViewModel()
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @State private var showPhotosPicker: Bool = false

  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          header
            .padding(.horizontal)
            .disabled(viewModel.isUploading)

          TextField(String(localized: "What's happening?", bundle: .module), text: $viewModel.text, axis: .vertical)
            .submitLabel(.return)
            .writingToolsBehavior(.complete)
            .padding(.horizontal)
            .disabled(viewModel.isUploading)
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
              .disabled(viewModel.isUploading)
          }
        }
        .padding(.vertical)
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(String(localized: "Write", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(String(localized: "Close", bundle: .module), systemImage: "xmark") {
            dismiss()
          }
          .disabled(viewModel.isUploading)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(
            role: .confirm,
            action: {
              Task {
                if await viewModel.submitPost() {
                  dismiss()
                }
              }
            }, label: {
              if viewModel.isUploading {
                ProgressView()
                  .tint(.white)
              } else {
                Label(String(localized: "Done", bundle: .module), systemImage: "arrow.up")
              }
            }
          )
          .disabled(viewModel.text.isEmpty)
          .disabled(viewModel.text.count > 280)
          .disabled(viewModel.isUploading)
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button(String(localized: "Photo Library", bundle: .module), systemImage: "photo.on.rectangle") {
            showPhotosPicker = true
          }
          .disabled(viewModel.isUploading)
        }
      }
    }
    .alert(
      viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      }, message: {
        Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
      }
    )
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
    .analyticsScreen(name: "Feed Compose", class: String(describing: Self.self))
  }

  var header: some View {
    HStack {
      profileImage

      Menu {
        Picker(selection: $viewModel.selectedComposeType, label: EmptyView()) {
          ForEach(FeedPostComposeViewModel.ComposeType.allCases) { type in
            Text(type.prettyString(nickname: viewModel.feedUser?.nickname))
              .tag(type)
          }
        }
      } label: {
        Text(viewModel.selectedComposeType.prettyString(nickname: viewModel.feedUser?.nickname))
          .lineLimit(1)
      }
      .tint(.primary)
      .buttonStyle(.glass)

      Spacer()

      Button {
        openURL(Constants.termsOfUseURL)
      } label: {
        Text("terms of use", bundle: .module)
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
}

#Preview {
  FeedPostComposeView()
}
