//
//  FeedCommentRow.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import SwiftUI
import NukeUI
import Translation
import BuddyDomain
import BuddyFeatureShared

struct FeedCommentRow: View {
  @Binding var comment: FeedComment
  let isReply: Bool
  let onReply: (() -> Void)?

  @State private var viewModel: FeedCommentRowViewModelProtocol = FeedCommentRowViewModel()

  @State private var showFullContent: Bool = false
  @State private var canBeExpanded: Bool = false

  @State private var showTranslateSheet: Bool = false
  @State private var showPopover: Bool = false
  @State private var safariSheetURL: URL? = nil

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      if isReply {
        Image(systemName: "arrow.turn.down.right")
          .padding(.top, 4)
      }
      VStack(alignment: .leading) {
        header

        content

        footer
      }
    }
    .translationPresentation(isPresented: $showTranslateSheet, text: comment.content)
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
    if let url = comment.profileImageURL {
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

      Group {
        if comment.isAuthor {
          Text(comment.authorName + " (\(authorTag.localized()))")
            .foregroundStyle(.tint)
        } else {
          Text(comment.authorName)
        }
      }
      .fontWeight(.semibold)
      .font(.callout)

      if comment.isKaistIP {
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

      Text(comment.createdAt.timeAgoDisplay)
        .foregroundStyle(.secondary)
        .font(.callout)

      Spacer()

      Menu("More", systemImage: "ellipsis") {
        Button("Translate", systemImage: "translate") { showTranslateSheet = true }
        Divider()
        if comment.isMyComment {
          Button("Delete", systemImage: "trash", role: .destructive) {
            Task {
              await viewModel.delete(comment: $comment)
            }
          }
        } else {
          Menu("Report", systemImage: "exclamationmark.triangle.fill") {
            ForEach(FeedReportType.allCases) { reason in
              Button(reason.description) {
                Task {
                  await viewModel.reportComment(commentID: comment.id, reason: reason)
                }
              }
            }
          }
        }
      }
    }
    .labelStyle(.iconOnly)
  }

  @ViewBuilder
  var content: some View {
    Text(comment.isDeleted ?
         "This comment has been deleted."
         : comment.content.toDetectedAttributedString())
      .lineLimit(showFullContent ? nil : 3)
      .textSelection(.enabled)
      .foregroundStyle(comment.isDeleted ? .secondary : .primary)
      .contentTransition(.numericText())
      .animation(.spring, value: comment)
      .background {
        ViewThatFits(in: .vertical) {
          Text(comment.content)
            .hidden()

          Color.clear.onAppear {
            canBeExpanded = true
          }
        }
      }
      .environment(\.openURL, OpenURLAction(handler: handleURL))

    if canBeExpanded && !showFullContent && !comment.isDeleted {
      Button("more") {
        withAnimation {
          showFullContent = true
        }
      }
      .foregroundStyle(.secondary)
    }
  }

  var footer: some View {
    HStack {
      Spacer()

      if comment.parentCommentID == nil {
        PostCommentButton(commentCount: comment.replyCount) {
          onReply?()
        }
      }

      if !comment.isDeleted {
        PostVoteButton(
          myVote: comment.myVote == .up ? true : comment.myVote == .down ? false : nil,
          votes: comment.upvotes - comment.downvotes,
          onDownvote: {
            await viewModel.downvote(comment: $comment)
          }, onUpvote: {
            await viewModel.upvote(comment: $comment)
          }
        )
        .disabled(comment.isMyComment)
      }
    }
    .font(.caption)
    .transition(.blurReplace)
    .animation(.spring, value: comment)
    .frame(height: 20)
  }

  private func handleURL(_ url: URL) -> OpenURLAction.Result {
    if let deepLink = DeepLink(url: url) {
      NotificationCenter.default.post(name: .buddyInternalDeepLink, object: deepLink)
      return .handled
    }

    safariSheetURL = url
    return .handled
  }

  private let authorTag = LocalizedString(["en": "Author", "ko": "작성자"])
}

#Preview {
  return
    LazyVStack {
      ForEach(.constant(FeedComment.mockList)) {
        FeedCommentRow(comment: $0, isReply: false, onReply: nil)
      }
    }
    .padding()
}
