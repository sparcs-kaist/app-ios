//
//  PostCommentCellHeader.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import BuddyDomain

/// Author, timestamp, and the actions menu for a comment.
struct PostCommentCellHeader: View {
  let authorProfileURL: URL?
  let authorNickname: String
  let timeText: String
  let isDeleted: Bool
  let isMine: Bool?
  /// `nil` for replies, which can't be replied to.
  let onReply: (() -> Void)?
  let onEdit: (() -> Void)?
  /// Whether the signed-in user has blocked the author.
  let isAuthorBlocked: Bool
  /// `nil` for authors who can't be blocked: the signed-in user, and anyone anonymous or under
  /// their real name.
  let onSetAuthorBlocked: ((Bool) -> Void)?
  let onTranslate: () -> Void
  let onReport: (AraContentReportType) async -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack {
      PostAuthorAvatar(url: authorProfileURL)

      Text(authorNickname)
        .fontWeight(.medium)

      Text(timeText)
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
      if let onReply {
        Button(String(localized: "Reply", bundle: .module), systemImage: "arrowshape.turn.up.left") {
          onReply()
        }
      }

      if isMine == false {
        // show report menu
        Menu(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle.fill") {
          ForEach(AraContentReportType.allCases, id: \.self) { type in
            Button(type.prettyString) {
              Task {
                await onReport(type)
              }
            }
          }
        }

        if let onSetAuthorBlocked {
          if isAuthorBlocked {
            Button(String(localized: "Unblock Author", bundle: .module), systemImage: "person.crop.circle.badge.checkmark") {
              onSetAuthorBlocked(false)
            }
          } else {
            Button(String(localized: "Block Author", bundle: .module), systemImage: "person.crop.circle.badge.xmark", role: .destructive) {
              onSetAuthorBlocked(true)
            }
          }
        }
      } else if isMine == true {
        // show edit button
        Button(String(localized: "Edit", bundle: .module), systemImage: "square.and.pencil") {
          onEdit?()
        }
      }

      Divider()

      Button(String(localized: "Translate", bundle: .module), systemImage: "translate") {
        onTranslate()
      }

      if isMine == true {
        Divider()

        Button(String(localized: "Delete", bundle: .module), systemImage: "trash", role: .destructive) {
          onDelete()
        }
      }
    } label: {
      Label(String(localized: "More", bundle: .module), systemImage: "ellipsis")
        .padding(8)
        .contentShape(.rect)
    }
    .labelStyle(.iconOnly)
    .transition(.blurReplace)
  }
}
