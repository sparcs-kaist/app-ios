//
//  PostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/01/2025.
//

import SwiftUI
import PhotosUI

struct PostComposeView: View {
  @State private var viewModel: PostComposeViewModelProtocol

  @Environment(\.dismiss) private var dismiss

  @FocusState private var isTitleFocused
  @FocusState private var isDescriptionFocused
  
  @State private var isShowingCancelDialog = false
  @State private var showPhotosPicker: Bool = false

  init(board: AraBoard) {
    _viewModel = State(initialValue: PostComposeViewModel(board: board))
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading) {
          topicSelector
            .padding(.horizontal)

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

          Divider()
            .padding(.horizontal)

          TextField("What's happening?", text: $viewModel.content, axis: .vertical)
            .focused($isDescriptionFocused)
            .submitLabel(.return)
            .writingToolsBehavior(.complete)
            .padding(.horizontal)

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
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "arrow.up", role: .confirm) {
            Task {
              await viewModel.writePost()
              dismiss()
            }
          }
          .disabled(viewModel.title.isEmpty)
          .disabled(viewModel.content.isEmpty)
        }
      }
      .toolbar {
        // Bottom tool bar
        ToolbarSpacer(.flexible, placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
          Button("Photo Library", systemImage: "photo.on.rectangle") {
            showPhotosPicker = true
          }
        }

        ToolbarItem(placement: .bottomBar) {
          Button("Attach File", systemImage: "paperclip") { }
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
        }
      }
      .photosPicker(
        isPresented: $showPhotosPicker,
        selection: $viewModel.selectedItems,
        maxSelectionCount: 10,
        matching: .images,
        photoLibrary: .shared()
      )
    }
  }

  private var termsOfUseButton: some View {
    HStack {
      Spacer()
      Button {

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
