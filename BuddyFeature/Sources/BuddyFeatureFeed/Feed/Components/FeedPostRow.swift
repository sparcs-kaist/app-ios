//
//  FeedPostRow.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI
import BuddyDomain
import BuddyFeatureShared
import Factory
import BuddyPreviewSupport

struct FeedPostRow: View {
  @Binding var post: FeedPost
  let onPostDeleted: ((String) -> Void)?
  let onComment: (() -> Void)?
  @State var showFullContent: Bool = false

  @State private var viewModel: FeedPostRowViewModelProtocol = FeedPostRowViewModel()
  @State private var canBeExpanded: Bool = false

  @State private var showDeleteConfirmation: Bool = false
  @State private var showTranslateSheet: Bool = false
  @State private var showPopover: Bool = false
  @State private var safariSheetURL: URL? = nil

  var body: some View {
    Group {
      VStack(alignment: .leading) {
        header

        content

        footer
      }
    }
    .translationPresentation(
      isPresented: $showTranslateSheet,
      text: post.content
    )
    .alert(
      viewModel.alertState?.title ?? "Error",
      isPresented: $viewModel.isAlertPresented,
      actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(viewModel.alertState?.message ?? "Unexpected Error")
      }
    )
    .sheet(item: $safariSheetURL) { url in
      SafariViewWrapper(url: url)
    }
  }

  @ViewBuilder
  var profileImage: some View {
    if let url = post.profileImageURL {
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
  }

  var header: some View {
    HStack {
      profileImage

      Text(post.authorName)
        .fontWeight(.semibold)
        .font(.callout)

      if post.isKaistIP {
        Image(systemName: "checkmark.seal.fill")
          .foregroundStyle(.tint)
          .scaleEffect(0.9)
          .popover(isPresented: $showPopover) {
            Text("This post was created from within the KAIST network.")
              .frame(width: 200)
              .presentationCompactAdaptation(.popover)
              .padding()
          }
          .onTapGesture {
            showPopover = true
          }
          .accessibilityLabel(Text("This post was created from within the KAIST network."))
      }

      // onPostDeleted == nil here means FeedPostRow is in the FeedPostView.
      Text(onPostDeleted != nil ? post.createdAt.timeAgoDisplay : post.createdAt.relativeTimeString)
        .foregroundStyle(.secondary)
        .font(.callout)

      Spacer()

      if onPostDeleted != nil {
        Menu("More", systemImage: "ellipsis") {
          Button("Translate", systemImage: "translate") { showTranslateSheet = true }
          Divider()
          if post.isAuthor {
            Button("Delete", systemImage: "trash", role: .destructive) {
              showDeleteConfirmation = true
            }
          } else {
            Menu("Report", systemImage: "exclamationmark.triangle.fill") {
              ForEach(FeedReportType.allCases) { reason in
                Button(reason.description) {
                  Task {
                    await viewModel.reportPost(postID: post.id, reason: reason)
                  }
                }
              }
            }
          }
        }
        .labelStyle(.iconOnly)
        .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
          Button("Delete", role: .destructive) {
            Task {
              onPostDeleted?(post.id)
            }
          }
          Button("Cancel", role: .cancel) { }
        } message: {
          Text("Are you sure you want to delete this post?")
        }
      }
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  var content: some View {
    Text(post.content.toDetectedAttributedString())
      .textSelection(.enabled)
      .padding(.horizontal)
      .lineLimit(showFullContent ? nil : 5)
      .background {
        ViewThatFits(in: .vertical) {
          Text(post.content)
            .hidden()
          Color.clear.onAppear {
            canBeExpanded = true
          }
        }
      }
      .environment(\.openURL, OpenURLAction(handler: handleURL))
    if canBeExpanded && !showFullContent {
      Button("more") {
        withAnimation {
          showFullContent = true
        }
      }
      .padding(.horizontal)
      .foregroundStyle(.secondary)
    }
    if !post.images.isEmpty {
      PostImagesStrip(images: post.images)
    }
  }

  var footer: some View {
    HStack {
      PostVoteButton(
        myVote: post.myVote == .up ? true : post.myVote == .down ? false : nil,
        votes: post.upvotes - post.downvotes,
        onDownvote: {
          await viewModel.downvote(post: $post)
        }, onUpvote: {
          await viewModel.upvote(post: $post)
        }
      )

      PostCommentButton(commentCount: post.commentCount) {
        onComment?()
      }
      .allowsHitTesting(onComment != nil)

      Spacer()
    }
    .padding(.horizontal)
    .padding(.top, 4)
  }

  private func handleURL(_ url: URL) -> OpenURLAction.Result {
    if let deepLink = DeepLink(url: url) {
      NotificationCenter.default.post(name: .buddyInternalDeepLink, object: deepLink)
      return .handled
    }

    safariSheetURL = url
    return .handled
  }
}

// MARK: - Previews

#Preview("With Actions") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(post: .constant(FeedPost.mock), onPostDeleted: { _ in }, onComment: { })
    .environment(spoilerContents)
}

#Preview("Without Actions") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(post: .constant(FeedPost.mock), onPostDeleted: nil, onComment: nil)
    .environment(spoilerContents)
}

#Preview("Anonymous") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[4]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}

#Preview("Long Content") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[6]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}

#Preview("Multiple Images") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[5]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}

#Preview("URL Content") {
  @Previewable @State var spoilerContents = SpoilerContents()
  FeedPostRow(
    post: .constant(FeedPost.mockList[8]),
    onPostDeleted: { _ in },
    onComment: { }
  )
  .environment(spoilerContents)
}
