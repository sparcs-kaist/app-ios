//
//  PostCommentCell.swift
//  soap
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import Foundation
import SwiftUI
import Translation
import BuddyDomain
import BuddyFeatureShared
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "PostCommentCell")

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

  @State private var alertState: AlertState? = nil
  @State private var isAlertPresented: Bool = false
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

        PostCommentCellHeader(
          authorProfileURL: comment.author.profile.profilePictureURL,
          authorNickname: comment.author.profile.nickname,
          timeText: comment.createdAt.timeAgoDisplay,
          isDeleted: isDeleted,
          isMine: comment.isMine,
          onEdit: onEdit,
          onTranslate: { showTranslateSheet = true },
          onReport: { type in await report(type: type) },
          onDelete: { Task { onDelete?(); await onDeleteComment() } }
        )
        .animation(.spring, value: isDeleted)

        Text(comment.content ?? String(localized: "This comment has been deleted.", bundle: .module))
          .foregroundStyle(isDeleted ? .secondary : .primary)
          .font(.callout)
          .contentTransition(.numericText())
          .animation(.spring, value: comment.content)

        PostCommentCellFooter(
          isThreaded: isThreaded,
          isDeleted: isDeleted,
          replyCount: comment.comments.count,
          myVote: comment.myVote,
          votes: comment.upvotes - comment.downvotes,
          isMine: comment.isMine,
          onComment: onComment,
          onUpvote: onUpvote,
          onDownvote: onDownvote
        )
        .animation(.spring, value: comment.upvotes - comment.downvotes)
      }
    }
    .alert(alertState?.title ?? String(localized: "Error", bundle: .module), isPresented: $isAlertPresented, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text(alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
    })
    .translationPresentation(isPresented: $showTranslateSheet, text: comment.content ?? "")
  }

  private func report(type: AraContentReportType) async {
    do {
      try await onReport(type)
      showAlert(title: String(localized: "Report Submitted", bundle: .module), content: String(localized: "Your report has been submitted successfully.", bundle: .module))
    } catch {
      logger.error("Failed to submit report: \(error.localizedDescription, privacy: .public)")
      showAlert(title: String(localized: "Unable to submit report.", bundle: .module), content: error.localizedDescription)
    }
  }

  private func showAlert(title: String, content: String) {
    alertState = .init(title: title, message: content)
    isAlertPresented = true
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
