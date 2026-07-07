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
  let onEdit: (() -> Void)?
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
