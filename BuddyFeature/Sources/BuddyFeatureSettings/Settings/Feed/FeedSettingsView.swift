//
//  FeedSettingsView.swift
//  BuddyFeature
//
//  Created by 하정우 on 2/20/26.
//

import SwiftUI
import PhotosUI
import UIKit
import NukeUI
import BuddyDomain
import BuddyPreviewSupport
import FirebaseAnalytics

struct FeedSettingsView: View {
  @State private var viewModel: FeedSettingsViewModelProtocol
  
  @Environment(\.dismiss) private var dismiss
  
  init(viewModel: FeedSettingsViewModelProtocol = FeedSettingsViewModel()) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    List {
      switch viewModel.state {
      case .loading:
        loadingView
          .redacted(reason: .placeholder)
      case .loaded:
        loadedView
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .analyticsScreen(name: "Feed Settings", class: String(describing: Self.self))
    .disabled(viewModel.isUpdatingProfile)
    .task {
      await viewModel.fetchUser()
    }
    .navigationTitle("Feed")
    .navigationBarBackButtonHidden(viewModel.isUpdatingProfile)
    .toolbar {
      ToolbarItem(placement: .confirmationAction, content: {
        Button(role: .confirm, action: {
          Task {
            await viewModel.updateProfile()
            dismiss()
          }
        }, label: {
          if viewModel.isUpdatingProfile {
            ProgressView()
          } else {
            Image(systemName: "checkmark")
          }
        })
        .disabled(!editButtonEnabled || viewModel.isUpdatingProfile)
      })
    }
  }
  
  @ViewBuilder
  private var loadingView: some View {
    Section {
      placeholderImage
    }
    .frame(maxWidth: .infinity)
    .listRowBackground(Color.clear)
    RowElementView(title: "Nickname", content: "Nickname")
    RowElementView(title: "Karma", content: "0")
  }
  
  @ViewBuilder
  private var loadedView: some View {
    Section {
      profileImage
        .aspectRatio(contentMode: .fill)
        .clipShape(Circle())
        .frame(width: 200, height: 200)
        .overlay(alignment: .bottomTrailing) {
          PhotosPicker(
            selection: $viewModel.selectedProfileImageItem,
            matching: .images
          ) {
            Image(systemName: "pencil.circle.fill")
              .symbolRenderingMode(.multicolor)
              .font(.system(size: 45))
              .foregroundStyle(Color.accentColor)
          }
          .frame(width: 45, height: 45)
        }
        .overlay(alignment: .bottomLeading) {
          Button(action: {
            Task {
              await viewModel.removeProfileImage()
            }
          }) {
            Image(systemName: "trash.circle.fill")
              .symbolRenderingMode(.multicolor)
              .font(.system(size: 45))
              .foregroundStyle(Color.accentColor)
          }
          .frame(width: 45, height: 45)
        }
    }
    .frame(maxWidth: .infinity)
    .listRowBackground(Color.clear)
    .buttonStyle(.plain)
    HStack {
      Text("Nickname")
      Spacer()
      TextField("Nickname", text: $viewModel.nickname)
        .autocorrectionDisabled(true)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(.secondary)
    }
    RowElementView(title: "Karma", content: "\(viewModel.feedUser?.karma ?? 0)")
  }
  
  private var placeholderImage: some View {
    Circle()
      .fill(Color.secondarySystemGroupedBackground)
      .frame(width: 200, height: 200)
      .overlay {
        Text("😀")
          .font(.largeTitle)
      }
  }
  
  private var profileImage: some View {
    Group {
      switch viewModel.profileImageState {
      case .noChange:
        lazyProfileImage
      case .removed:
        placeholderImage
      case .updated(let uiImage):
        Image(uiImage: uiImage)
          .resizable()
      case .loading:
        ProgressView()
      case .error:
        Image(systemName: "exclamationmark.triangle.fill")
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
  }
  
  @ViewBuilder private var lazyProfileImage: some View {
    if let imageURL = viewModel.profileImageURL {
      LazyImage(url: imageURL) { state in
        if let image = state.image {
          image
            .resizable()
        } else {
          ProgressView()
        }
      }
    } else {
      placeholderImage
    }
  }
  
  private var editButtonEnabled: Bool {
    let hasChanged = (viewModel.profileImageState != .noChange) || (viewModel.nickname != viewModel.feedUser?.nickname)
    
    return !viewModel.nickname.isEmpty && hasChanged
  }
}

#Preview {
  @Previewable @State var viewModel = PreviewFeedSettingsViewModel()
  
  NavigationStack {
    FeedSettingsView(viewModel: viewModel)
  }
}
