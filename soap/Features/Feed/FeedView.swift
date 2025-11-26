//
//  FeedView.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import SwiftUI
import Factory
import NukeUI
import BuddyDomain

struct FeedView: View {
  @State private var viewModel: FeedViewModelProtocol = FeedViewModel()
  @Namespace private var namespace

  @State private var showSettingsSheet: Bool = false
  @State private var showComposeView: Bool = false

  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""
  @State private var showAlert: Bool = false
  
  @State private var spoilerContents = SpoilerContents()
  
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  init(_ viewModel: FeedViewModelProtocol = FeedViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 0) {
          Group {
            switch viewModel.state {
            case .loading:
              ForEach(.constant(FeedPost.mockList)) { $post in
                FeedPostRow(post: $post, onPostDeleted: nil, onComment: nil)
                  .environment(spoilerContents)
                  .padding(.vertical)

                Divider()
                  .padding(.horizontal)
              }
              .redacted(reason: .placeholder)
            case .loaded:
              ForEach($viewModel.posts) { $post in
                NavigationLink(destination: {
                  FeedPostView(post: $post, onDelete: {
                    if let idx = viewModel.posts.firstIndex(where: { $0.id == post.id }) {
                      Task {
                        try? await viewModel.deletePost(postID: post.id)
                        viewModel.posts.remove(at: idx)
                      }
                    }
                  })
                  .environment(spoilerContents)
                  .addKeyboardVisibilityToEnvironment() // TODO: This should be changed to @FocusState, but it's somehow doesn't work with .safeAreaBar in the early stage of iOS 26.
  //                .navigationTransition(.zoom(sourceID: post.id, in: namespace))
                }, label: {
                  FeedPostRow(post: $post, onPostDeleted: { postID in
                    Task {
                      do {
                        try await viewModel.deletePost(postID: postID)
                      } catch {
                        showAlert(title: String(localized: "Error"), message: String(localized: "Failed to delete a post. Please try again later."))
                      }
                    }
                  }, onComment: nil)
                  .environment(spoilerContents)
                  .contentShape(.rect)
                })
                .id(post.id)
                .padding(.vertical)
                .navigationLinkIndicatorVisibility(.hidden)
                .buttonStyle(.plain)
                .matchedTransitionSource(id: post.id, in: namespace)

                Divider()
                  .padding(.horizontal)
              }
            case .error(let message):
              ContentUnavailableView(
                "Error",
                systemImage: "questionmark.text.page",
                description: Text(message)
              )
            }
          }
          .containerRelativeFrame([.horizontal], alignment: .center, { length, _ in
            if horizontalSizeClass == .compact {
              return length
            }
            if isPortrait {
              return length / 1.25
            }
            return length / 1.75
          })
        }
        .animation(.spring, value: viewModel.posts)
      }
      .disabled(viewModel.state == .loading)
      .navigationTitle(horizontalSizeClass == .compact ? String(localized: "Feed") : "")
      .toolbarTitleDisplayMode(.inlineLarge)
      .task {
        await viewModel.fetchInitialData()
      }
      .refreshable {
        await viewModel.fetchInitialData()
      }
      .toolbar {
        ToolbarItem {
          Button("Write", systemImage: "square.and.pencil") {
            showComposeView = true
          }
        }
        .matchedTransitionSource(id: "ComposeView", in: namespace)

        ToolbarSpacer(.fixed)
        
        ToolbarItem {
          Button("Settings", systemImage: "gear") {
            showSettingsSheet = true
          }
        }
      }
      .sheet(isPresented: $showSettingsSheet) {
        SettingsView()
          .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $showComposeView, onDismiss: {
        Task {
          await viewModel.fetchInitialData()
        }
      }) {
        FeedPostComposeView()
          .navigationTransition(.zoom(sourceID: "ComposeView", in: namespace))
          .interactiveDismissDisabled()
      }
      .alert(alertTitle, isPresented: $showAlert, actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(alertMessage)
      })
      .background {
        BackgroundGradientView(color: .accentColor)
          .ignoresSafeArea()
      }
    }
  }

  private func showAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showAlert = true
  }
  
  private var isPortrait: Bool {
    if UIDevice.current.orientation.isValidInterfaceOrientation {
      return UIDevice.current.orientation.isPortrait
    }
    
    // fallback to portrait when not available
    
    guard let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }) else {
      return true
    }
    
    return ![.landscapeLeft, .landscapeRight].contains(windowScene.effectiveGeometry.interfaceOrientation)
  }
}


#Preview("Loading State") {
  @Previewable @State var viewModel = MockFeedViewModel()
  viewModel.state = .loading
  
  return FeedView(viewModel)
}

#Preview("Loaded State") {
  @Previewable @State var viewModel = MockFeedViewModel()
  FeedView(viewModel)
}

#Preview("Error State") {
  @Previewable @State var viewModel = MockFeedViewModel()
  viewModel.state = .error(message: "Something went wrong")
  
  return FeedView(viewModel)
}
