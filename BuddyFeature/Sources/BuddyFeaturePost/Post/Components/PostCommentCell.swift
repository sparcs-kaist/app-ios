//
//  PostCommentCell.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import NukeUI
import Translation
import BuddyDomain
import BuddyFeatureShared

struct PostCommentCell: View {
  @Binding var comment: AraPostComment
  let isThreaded: Bool
  let onComment: (() -> Void)?
  let onDelete: (() -> Void)?
  let onEdit: (() -> Void)?
  let onUpvote: () async -> Void
  let onDownvote: () async -> Void
  let onReport: (AraContentReportType) async throws -> Void
  let onDeleteComment: () async -> Void

  @State private var presentAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertContent: String = ""
  @State private var showTranslateSheet: Bool = false

  var body: some View {
    // is this comment deleted?
    let isDeleted: Bool = comment.content == nil

    HStack(alignment: .top, spacing: 8) {
      if isThreaded {
        Image(systemName: "arrow.turn.down.right")
      }

      VStack(alignment: .leading, spacing: 8) {
        Divider()

        header

        Text(comment.content ?? "This comment has been deleted.")
          .foregroundStyle(isDeleted ? .secondary : .primary)
          .font(.callout)
          .contentTransition(.numericText())
          .animation(.spring, value: comment)

        footer
      }
    }
    .alert(alertTitle, isPresented: $presentAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(alertContent)
    })
    .translationPresentation(isPresented: $showTranslateSheet, text: comment.content ?? "")
  }

  private var footer: some View {
    HStack {
      let isDeleted: Bool = comment.content == nil
      Spacer()

      if !isThreaded {
        PostCommentButton(commentCount: comment.comments.count) {
          onComment?()
        }
        .fixedSize()
      }

      if !isDeleted {
        PostVoteButton(
          myVote: comment.myVote,
          votes: comment.upvotes - comment.downvotes,
          onDownvote: {
            await onDownvote()
          },
          onUpvote: {
            await onUpvote()
          }
        )
        .disabled(comment.isMine ?? false)
        .fixedSize()
      }
    }
    .font(.caption)
    .transition(.blurReplace)
    .animation(.spring, value: comment)
  }

  private var header: some View {
    HStack {
      let isDeleted: Bool = comment.content == nil
      profilePicture

      Text(comment.author.profile.nickname)
        .fontWeight(.medium)

      Text(comment.createdAt.timeAgoDisplay)
        .font(.caption)
        .foregroundStyle(.secondary)

      Spacer()

      if !isDeleted {
        actionsMenu
      }
    }
    .font(.callout)
  }

  private var actionsMenu: some View {
    Menu {
      if comment.isMine == false {
        // show report menu
        Menu("Report", systemImage: "exclamationmark.triangle.fill") {
          ForEach(AraContentReportType.allCases, id: \.self) { type in
            Button(type.prettyString) {
              Task {
                await report(type: type)
              }
            }
          }
        }
      } else if comment.isMine == true {
        // show edit button
        Button("Edit", systemImage: "square.and.pencil") {
          onEdit?()
        }
      }

      Divider()

      Button("Translate", systemImage: "translate") {
        showTranslateSheet = true
      }

      if comment.isMine == true {
        Divider()

        Button("Delete", systemImage: "trash", role: .destructive) {
          Task {
            onDelete?()
            await onDeleteComment()
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

  @ViewBuilder
  private var profilePicture: some View {
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

  private func report(type: AraContentReportType) async {
    do {
      try await onReport(type)
      showAlert(title: String(localized: "Report Submitted"), content: String(localized: "Your report has been submitted successfully."))
    } catch {
    }
  }

  private func showAlert(title: String, content: String) {
    alertTitle = title
    alertContent = content
    presentAlert = true
  }
}


#Preview {
  PostCommentCell(
    comment: .constant(AraPostComment.mock),
    isThreaded: false,
    onComment: nil,
    onDelete: nil,
    onEdit: nil,
    onUpvote: {},
    onDownvote: {},
    onReport: { _ in },
    onDeleteComment: {}
  )
  .padding()
  PostCommentCell(
    comment: .constant(AraPostComment.mock),
    isThreaded: true,
    onComment: nil,
    onDelete: nil,
    onEdit: nil,
    onUpvote: {},
    onDownvote: {},
    onReport: { _ in },
    onDeleteComment: {}
  )
  .padding()
}
