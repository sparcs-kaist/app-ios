//
//  FeedCommentRow.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import SwiftUI
import NukeUI
import Factory

struct FeedCommentRow: View {
  @Binding var comment: FeedComment
  let isReply: Bool
  let onReply: (() -> Void)?
  
  @State private var showAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""
  
  @State private var showFullContent: Bool = false
  @State private var canBeExpanded: Bool = false
  
  // MARK: - Dependencies
  @Injected(
    \.feedCommentRepository
  ) private var feedCommentRepository: FeedCommentRepositoryProtocol

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
            .foregroundStyle(.accent)
        } else {
          Text(comment.authorName)
        }
      }
        .fontWeight(.semibold)
        .font(.callout)

      Text(comment.createdAt.timeAgoDisplay)
        .foregroundStyle(.secondary)
        .font(.callout)

      Spacer()

      Menu("More", systemImage: "ellipsis") {
        if comment.isMyComment {
          Button("Delete", systemImage: "trash", role: .destructive) {
            Task {
              await delete()
            }
          }
        }
        Menu("Report", systemImage: "exclamationmark.triangle.fill") {
          ForEach(FeedReportType.allCases) { reason in
            Button(reason.description) {
              Task {
                do {
                  try await feedCommentRepository.reportComment(commentID: comment.id, reason: reason, detail: "")
                  showAlert(title: String(localized: "Report Submitted"), message: String(localized: "Your report has been submitted successfully."))
                } catch {
                  // TODO: error handling
                }
              }
            }
          }
        }
      }
    }
    .alert(alertTitle, isPresented: $showAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(alertMessage)
    })
    .labelStyle(.iconOnly)
  }

  @ViewBuilder
  var content: some View {
    Text(comment.isDeleted ? "This comment has been deleted." : comment.content)
      .lineLimit(showFullContent ? nil : 3)
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
    
    if canBeExpanded && !showFullContent {
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
            await downvote()
          }, onUpvote: {
            await upvote()
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

  // MARK: - Functions
  private func upvote() async {
    let previousMyVote: FeedVoteType? = comment.myVote
    let previousUpvotes: Int = comment.upvotes

    do {
      if previousMyVote == .up {
        // cancel upvote
        comment.myVote = nil
        comment.upvotes -= 1
        try await feedCommentRepository.deleteVote(commentID: comment.id)
      } else {
        // upvote
        if previousMyVote == .down {
          // remove downvote if there was
          comment.downvotes -= 1
        }
        comment.myVote = .up
        comment.upvotes += 1
        try await feedCommentRepository.vote(commentID: comment.id, type: .up)
      }
    } catch {
      logger.error(error)
      comment.myVote = previousMyVote
      comment.upvotes = previousUpvotes
    }
  }

  private func downvote() async {
    let previousMyVote: FeedVoteType? = comment.myVote
    let previousDownvotes: Int = comment.downvotes

    do {
      if previousMyVote == .down {
        // cancel downvote
        comment.myVote = nil
        comment.downvotes -= 1
        try await feedCommentRepository.deleteVote(commentID: comment.id)
      } else {
        // downvote
        if previousMyVote == .up {
          // remove downvote if there was
          comment.upvotes -= 1
        }
        comment.myVote = .down
        comment.downvotes += 1
        try await feedCommentRepository.vote(commentID: comment.id, type: .down)
      }
    } catch {
      logger.error(error)
      comment.myVote = previousMyVote
      comment.downvotes = previousDownvotes
    }
  }

  private func delete() async {
    comment.isDeleted = true
    do {
      try await feedCommentRepository.deleteComment(commentID: comment.id)
    } catch {
      comment.isDeleted = false
    }
  }
  
  private let authorTag = LocalizedString(["en": "Author", "ko": "작성자"])
  
  private func showAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showAlert = true
  }
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
