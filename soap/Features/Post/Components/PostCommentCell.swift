//
//  PostCommentCell.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import NukeUI
import Factory

struct PostCommentCell: View {
  @Binding var comment: AraPostComment
  let isThreaded: Bool
  let onComment: (() -> Void)?
  let onDelete: (() -> Void)?

  // MARK: - Dependencies
  @Injected(\.araCommentRepository) private var araCommentRepository: AraCommentRepositoryProtocol

  var body: some View {
    // is this comment deleted?
    let isDeleted: Bool = comment.content == nil

    HStack(alignment: .top, spacing: 8) {
      if isThreaded {
        Image(systemName: "arrow.turn.down.right")
      }

      VStack(alignment: .leading, spacing: 8) {
        Divider()

        HStack {
          profilePicture

          Text(comment.author.profile.nickname)
            .fontWeight(.medium)

          Text(comment.createdAt.relativeTimeString)
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()

          if !isDeleted {
            Menu {
              if comment.isMine == false {
                // show report menu
                Menu("Report", systemImage: "exclamationmark.triangle.fill") {
                  Button("Hate Speech") { }
                  Button("Unauthorized Sales Post") { }
                  Button("Spam") { }
                  Button("False Information") { }
                  Button("Defamation") { }
                  Button("Other") { }
                }
              } else if comment.isMine == true {
                // show edit button
                Button("Edit", systemImage: "square.and.pencil") { }
              }

              Divider()

              Button("Translate", systemImage: "translate") { }
              Button("Summarise", systemImage: "text.append") { }

              if comment.isMine == true {
                Divider()

                Button("Delete", systemImage: "trash", role: .destructive) {
                  Task {
                    do {
                      try await araCommentRepository.deleteComment(commentID: comment.id)
                      comment.content = nil
                      onDelete?()
                    } catch {
                      logger.error(error)
                    }
                  }
                }
              }
            } label: {
              Label("More", systemImage: "ellipsis")
                .padding(8)
                .contentShape(.rect)
            }
            .labelStyle(.iconOnly)
            .transition(.blurReplace)
            .animation(.spring, value: comment)
          }
        }
        .font(.callout)

        Text(comment.content ?? "This comment has been deleted.")
          .foregroundStyle(isDeleted ? .secondary : .primary)
          .font(.callout)
          .contentTransition(.numericText())
          .animation(.spring, value: comment)

        if !isDeleted {
          HStack {
            Spacer()

            if !isThreaded {
              PostCommentButton(commentCount: comment.comments.count) {
                onComment?()
              }
              .fixedSize()
            }

            PostVoteButton(
              myVote: comment.myVote,
              votes: comment.upvotes - comment.downvotes,
              onDownvote: {
                Task {
                  await downvote()
                }
              },
              onUpvote: {
                Task {
                  await upvote()
                }
              }
            )
            .disabled(comment.isMine ?? false)
            .fixedSize()
          }
          .font(.caption)
          .transition(.blurReplace)
          .animation(.spring, value: comment)
        }
      }
    }
  }

  @ViewBuilder
  var profilePicture: some View {
    if let url = comment.author.profile.profilePictureURL {
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
      .frame(width: 21, height: 21)
      .clipShape(.circle)
    } else {
      Circle()
        .fill(Color.secondarySystemBackground)
        .frame(width: 21, height: 21)
    }
  }

  // MARK: - Functions
  private func upvote() async {
    let previousMyVote: Bool? = comment.myVote
    let previousUpvotes: Int = comment.upvotes

    do {
      if previousMyVote == true {
        // cancel upvote
        comment.myVote = nil
        comment.upvotes -= 1
        try await araCommentRepository.cancelVote(commentID: comment.id)
      } else {
        // upvote
        if previousMyVote == false {
          // remove downvote if there was
          comment.downvotes -= 1
        }
        comment.myVote = true
        comment.upvotes += 1
        try await araCommentRepository.upvoteComment(commentID: comment.id)
      }
    } catch {
      logger.error(error)
      comment.upvotes = previousUpvotes
      comment.myVote = previousMyVote
    }
  }

  func downvote() async {
    let previousMyVote: Bool? = comment.myVote
    let previousDownvotes: Int = comment.downvotes

    do {
      if previousMyVote == false {
        // cancel downvote
        comment.myVote = nil
        comment.downvotes -= 1
        try await araCommentRepository.cancelVote(commentID: comment.id)
      } else {
        // downvote
        if previousMyVote == true {
          // remove upvote if there was
          comment.upvotes -= 1
        }
        comment.myVote = false
        comment.downvotes += 1
        try await araCommentRepository.downvoteComment(commentID: comment.id)
      }
    } catch {
      logger.error(error)
      comment.downvotes = previousDownvotes
      comment.myVote = previousMyVote
    }
  }
}


#Preview {
  PostCommentCell(
    comment: .constant(AraPostComment.mock),
    isThreaded: false,
    onComment: nil,
    onDelete: nil
  )
  .padding()
  PostCommentCell(
    comment: .constant(AraPostComment.mock),
    isThreaded: true,
    onComment: nil,
    onDelete: nil
  )
  .padding()
}
