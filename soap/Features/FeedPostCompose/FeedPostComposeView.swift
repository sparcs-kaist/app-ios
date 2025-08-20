//
//  FeedPostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI

struct FeedPostComposeView: View {
  @State private var viewModel: FeedPostComposeViewModelProtocol = FeedPostComposeViewModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading) {
          header

          TextField("What's happening?", text: $viewModel.text, axis: .vertical)
            .submitLabel(.return)
            .writingToolsBehavior(.complete)
        }
        .padding()
      }
      .navigationTitle("Write")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "arrow.up", role: .confirm) { }
        }
      }
    }
    .task {
      await viewModel.fetchFeedUser()
    }
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
