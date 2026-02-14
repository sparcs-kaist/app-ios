//
//  PostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/01/2025.
//

import SwiftUI
import PhotosUI
import BuddyDomain
import FirebaseAnalytics

struct PostComposeView: View {
  @State private var viewModel: PostComposeViewModelProtocol

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @FocusState private var isTitleFocused
  @FocusState private var isDescriptionFocused

  @State private var isShowingCancelDialog = false
  @State private var showPhotosPicker: Bool = false

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  @State private var isUploading: Bool = false

  init(board: AraBoard) {
    _viewModel = State(initialValue: PostComposeViewModel(board: board))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          topicSelector
            .padding(.horizontal)
            .disabled(isUploading)

          Spacer()
            .frame(maxHeight: 16)

          TextField("Please enter the title", text: $viewModel.title)
            .font(.title3)
            .focused($isTitleFocused)
            .submitLabel(.next)
            .onSubmit {
              isDescriptionFocused = true
            }
            .writingToolsBehavior(.disabled)
            .padding(.horizontal)
            .disabled(isUploading)

          Divider()
            .padding(.horizontal)

          TextField("What's happening?", text: $viewModel.content, axis: .vertical)
            .focused($isDescriptionFocused)
            .submitLabel(.return)
            .writingToolsBehavior(.complete)
            .padding(.horizontal)
            .disabled(isUploading)

          if !viewModel.selectedImages.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                ForEach(viewModel.selectedImages, id: \.self) { image in
                  Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(.rect(cornerRadius: 8))
                }
              }
              .padding()
            }
          }

          termsOfUseButton
            .padding(.horizontal)

          Spacer()
        }
        .padding(.vertical)
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle("Write")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        // Top tool bar
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel", systemImage: "xmark", role: .close) {
            isShowingCancelDialog = true
          }
          .confirmationDialog(
            "Are you sure you want to discard this post?",
            isPresented: $isShowingCancelDialog,
            titleVisibility: .hidden
          ) {
            Button("Discard Post", role: .destructive) {
              dismiss()
            }
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
                  errorMessage = "Failed to write post. Please try again later."
                  showErrorAlert = true
                }
              }
            },
            label: {
              if isUploading {
                ProgressView()
              } else {
                Label("Done", systemImage: "arrow.up")
              }
            }
          )
          .disabled(viewModel.title.isEmpty)
          .disabled(viewModel.content.isEmpty)
          .disabled(isUploading)
        }
      }
      .toolbar {
        // Bottom tool bar
        ToolbarSpacer(.flexible, placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
          Button("Photo Library", systemImage: "photo.on.rectangle") {
            showPhotosPicker = true
          }
          .disabled(isUploading)
        }

        ToolbarItem(placement: .bottomBar) {
          Menu("More", systemImage: "ellipsis") {
            Button(action: {
              viewModel.writeAsAnonymous.toggle()
            }, label: {
              if viewModel.writeAsAnonymous {
                Image(systemName: "checkmark")
              }
              Text("Anonymous")
            })
            Button(action: {
              viewModel.isNSFW.toggle()
            }, label: {
              if viewModel.isNSFW {
                Image(systemName: "checkmark")
              }
              Text("NSFW")
            })
            Button(action: {
              viewModel.isPolitical.toggle()
            }, label: {
              if viewModel.isPolitical {
                Image(systemName: "checkmark")
              }
              Text("Political")
            })
          }
          .disabled(isUploading)
        }
      }
      .photosPicker(
        isPresented: $showPhotosPicker,
        selection: $viewModel.selectedItems,
        maxSelectionCount: 10,
        matching: .images,
        photoLibrary: .shared()
      )
      .alert("Error", isPresented: $showErrorAlert, actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(errorMessage)
      })
    }
    .analyticsScreen(name: "Ara Post Compose", class: String(describing: Self.self))
  }

  private var termsOfUseButton: some View {
    HStack {
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

  private var topicSelector: some View {
    Picker(selection: $viewModel.selectedTopic, label: EmptyView()) {
      Text("No topic")
        .tag(nil as AraBoardTopic?)

      ForEach(viewModel.board.topics ?? []) { topic in
        Text(topic.name.localized())
          .tag(topic)
      }
    }
    .pickerStyle(.menu)
    .tint(.primary)
    .buttonStyle(.glass)
  }
}

#Preview {
  PostComposeView(board: AraBoard.mockList[1])
}


