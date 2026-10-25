//
//  PostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/01/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import BuddyDomain
import FirebaseAnalytics
import TiptapEditor
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "PostComposeView")

struct PostComposeView: View {
  @State private var viewModel: PostComposeViewModelProtocol

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @FocusState private var isTitleFocused
  /// Plain state, not `@FocusState`: the price field is UIKit, and SwiftUI resets focus state that
  /// no `.focused` view claims, which would dismiss the keyboard after every keystroke.
  @State private var isPriceFocused = false

  @State private var isShowingCancelDialog = false
  @State private var showPhotosPicker: Bool = false
  @State private var showFileImporter = false
  @State private var pickedPhotos: [PhotosPickerItem] = []
  @State private var formatButtonFrame: CGRect?
  @Namespace private var composeBarGlass

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  @State private var isUploading: Bool = false

  /// Called once an edit is saved, so the post can be fetched again.
  private let onSaved: () -> Void

  init(board: AraBoard) {
    _viewModel = State(initialValue: PostComposeViewModel(board: board))
    self.onSaved = {}
  }

  /// Edits `post`. Its board, topic and name type can't change.
  init(editing post: AraPost, board: AraBoard, onSaved: @escaping () -> Void) {
    _viewModel = State(initialValue: PostComposeViewModel(editing: post, board: board))
    self.onSaved = onSaved
  }

  private var isEditingPost: Bool {
    viewModel.editingPost != nil
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          topicSelector
            .padding(.horizontal)
            // Ara keeps a post's topic once it's written.
            .disabled(isUploading || isEditingPost)

          Spacer()
            .frame(maxHeight: 16)

          TextField(String(localized: "Please enter the title", bundle: .module), text: $viewModel.title)
            .font(.title3)
            .focused($isTitleFocused)
            .submitLabel(.next)
            .onSubmit {
              if viewModel.board.isMarket {
                isPriceFocused = true
              } else {
                viewModel.editor.focus()
              }
            }
            .writingToolsBehavior(.disabled)
            .padding(.horizontal)
            .disabled(isUploading)

          if viewModel.board.isMarket {
            Divider()
              .padding(.horizontal)

            priceField
              .padding(.horizontal)
              .disabled(isUploading)
          }

          Divider()
            .padding(.horizontal)

          TiptapEditor(controller: viewModel.editor)
          .overlay(alignment: .topLeading) {
            if viewModel.editor.isEmpty {
              Group {
                if viewModel.board.isMarket {
                  Text("Describe the item: its condition, and how to reach you.", bundle: .module)
                } else {
                  Text("What's happening?", bundle: .module)
                }
              }
                .foregroundStyle(.tertiary)
                // Matches the text view's top inset, so it sits where typing starts.
                .padding(.top, 8)
                .allowsHitTesting(false)
            }
          }
          .padding(.horizontal)
          .disabled(isUploading)

          if !viewModel.files.isEmpty {
            ComposeFileList(files: viewModel.files) { viewModel.removeFile($0) }
              .padding(.horizontal)
              .disabled(isUploading)
          }

          termsOfUseButton
            .padding(.horizontal)

          Spacer()
        }
        .padding(.vertical)
        .contentWidth()
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(isEditingPost ? String(localized: "Edit Post", bundle: .module) : String(localized: "Write", bundle: .module))
      .overlay {
        if viewModel.isLoadingContent {
          ProgressView()
        }
      }
      .task {
        await viewModel.loadContentForEditing()
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        // Top tool bar. Semantic placements let the system move these into the vertical bar on
        // iPhone Duo; on iPhone and iPad they resolve to the same leading and trailing slots.
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "Cancel", bundle: .module), systemImage: "xmark", role: .close) {
            isShowingCancelDialog = true
          }
          .confirmationDialog(
            String(localized: "Are you sure you want to discard this post?", bundle: .module),
            isPresented: $isShowingCancelDialog,
            titleVisibility: .hidden
          ) {
            Button(
              isEditingPost ? String(localized: "Discard Changes", bundle: .module) : String(localized: "Discard Post", bundle: .module),
              role: .destructive
            ) {
              dismiss()
            }
          }
          .disabled(isUploading)
        }

        ToolbarItem(placement: .confirmationAction) {
          Button(
            role: .confirm,
            action: {
              Task {
                isUploading = true
                defer { isUploading = false }
                do {
                  try await viewModel.submit()
                  if isEditingPost {
                    onSaved()
                  }
                  dismiss()
                } catch {
                  logger.error("Failed to write post: \(error.localizedDescription, privacy: .public)")
                  errorMessage = error.localizedDescription
                  showErrorAlert = true
                }
              }
            },
            label: {
              if isUploading {
                ProgressView()
              } else {
                Label(String(localized: "Done", bundle: .module), systemImage: "arrow.up")
              }
            }
          )
          .disabled(viewModel.title.isEmpty)
          .disabled(viewModel.editor.isEmpty)
          .disabled(isUploading)
        }
      }
      .safeAreaBar(edge: .bottom) {
        composeBar
      }
      .photosPicker(
        isPresented: $showPhotosPicker,
        selection: $pickedPhotos,
        maxSelectionCount: 10,
        matching: .images,
        photoLibrary: .shared()
      )
      .fileImporter(
        isPresented: $showFileImporter,
        allowedContentTypes: ComposeFile.allowedTypes,
        allowsMultipleSelection: true
      ) { result in
        do {
          try withAnimation(.snappy) { try viewModel.addFiles(try result.get()) }
        } catch {
          logger.error("Failed to attach file: \(error.localizedDescription, privacy: .public)")
          errorMessage = error.localizedDescription
          showErrorAlert = true
        }
      }
      .onChange(of: pickedPhotos) { _, items in
        guard !items.isEmpty else { return }
        Task {
          var images: [UIImage] = []
          for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
              images.append(image)
            }
          }
          // Placed at the cursor, like a photo added in Notes.
          viewModel.editor.insertImages(images)
          pickedPhotos = []
        }
      }
      .alert(String(localized: "Error", bundle: .module), isPresented: $showErrorAlert, actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      }, message: {
        Text(errorMessage)
      })
    }
    .analyticsScreen(name: "Ara Post Compose", class: String(describing: Self.self))
  }

  /// The one bar for the whole composer, floating above the keyboard. Each group is its own
  /// glass shape in one container, so the controls that only make sense in the text (formatting
  /// and lists, hiding the keyboard) grow out of the main capsule while writing and merge back.
  private var composeBar: some View {
    GlassEffectContainer(spacing: 8) {
      HStack(spacing: 8) {
        if viewModel.editor.isEditing {
          HStack(spacing: 0) {
            barButton(String(localized: "Format", bundle: .module), systemImage: "textformat") {
              viewModel.editor.showFormatting(from: formatButtonFrame)
            }
            // Where the panel points from when it opens as a popover.
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { formatButtonFrame = $0 }
            barButton(String(localized: "Bulleted List", bundle: .module), systemImage: "list.bullet") {
              viewModel.editor.toggleBulletList()
            }
          }
          .padding(.horizontal, 4)
          .glassEffect(.regular.interactive(), in: .capsule)
          .glassEffectID(ComposeBarGlass.text, in: composeBarGlass)
        }

        HStack(spacing: 0) {
          barButton(String(localized: "Photo Library", bundle: .module), systemImage: "photo.on.rectangle") {
            showPhotosPicker = true
          }
          barButton(String(localized: "Attach File", bundle: .module), systemImage: "paperclip") {
            showFileImporter = true
          }
          optionsMenu
        }
        .padding(.horizontal, 4)
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectID(ComposeBarGlass.main, in: composeBarGlass)

        if viewModel.editor.isEditing {
          barButton(String(localized: "Hide Keyboard", bundle: .module), systemImage: "keyboard.chevron.compact.down") {
            viewModel.editor.dismissKeyboard()
          }
          .glassEffect(.regular.interactive(), in: .circle)
          .glassEffectID(ComposeBarGlass.keyboard, in: composeBarGlass)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding(.horizontal)
    // Floats clear of the keyboard rather than sitting on it.
    .padding(.bottom, 8)
    .animation(.snappy, value: viewModel.editor.isEditing)
    .disabled(isUploading)
  }

  private func barButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .labelStyle(.iconOnly)
        .font(.title3)
        .frame(width: 44, height: 44)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }

  private var optionsMenu: some View {
    // Not `ellipsis`: in a vertical bar that reads as the system's own overflow menu.
    Menu {
      // Ara keeps the name a post was written under, and some boards allow only one.
      if !isEditingPost && viewModel.canChooseAnonymity {
        Toggle(isOn: $viewModel.writeAsAnonymous) {
          Text("Anonymous", bundle: .module)
        }
      }
      Toggle(isOn: $viewModel.isNSFW) {
        Text("NSFW", bundle: .module)
      }
      Toggle(isOn: $viewModel.isPolitical) {
        Text("Political", bundle: .module)
      }

      // A listing is marked reserved or sold by editing it.
      if isEditingPost && viewModel.board.isMarket {
        Picker(selection: $viewModel.saleState) {
          Text("On Sale", bundle: .module).tag(AraMarketListing.State.onSale)
          Text("Reserved", bundle: .module).tag(AraMarketListing.State.reserved)
          Text("Sold", bundle: .module).tag(AraMarketListing.State.soldOut)
        } label: {
          Text("Status", bundle: .module)
        }
        .pickerStyle(.inline)
      }
    } label: {
      Label(String(localized: "More", bundle: .module), systemImage: "slider.horizontal.3")
        .labelStyle(.iconOnly)
        .font(.title3)
        .frame(width: 44, height: 44)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }

  /// The asking price, in won: "₩ 20,000" once typed.
  private var priceField: some View {
    HStack(spacing: 6) {
      Text(verbatim: "₩")
        .foregroundStyle(viewModel.price == nil ? .tertiary : .primary)
      PriceTextField(
        placeholder: String(localized: "Price", bundle: .module),
        value: $viewModel.price,
        isFocused: $isPriceFocused
      )
    }
    .font(.title3)
    .accessibilityElement(children: .combine)
  }

  private var termsOfUseButton: some View {
    HStack {
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

  private var topicSelector: some View {
    Picker(selection: $viewModel.selectedTopic, label: EmptyView()) {
      Text("No topic", bundle: .module)
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

/// The glass shapes of the compose bar, so they morph into one another as they appear.
private enum ComposeBarGlass: Hashable, Sendable {
  case text, main, keyboard
}
