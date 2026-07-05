//
//  FeedCommentRowHeader.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import SwiftUI
import BuddyDomain

/// Author, verification badge, timestamp, and the more/expand controls.
struct FeedCommentRowHeader: View {
  let profileImageURL: URL?
  let authorName: String
  let authorTagText: String
  let isAuthor: Bool
  let isMyComment: Bool
  let isKaistIP: Bool
  let timeText: String
  let downvotes: Int
  let showFullContent: Bool
  @Binding var isHiddenCommentExpanded: Bool
  let onTranslate: () -> Void
  let onDelete: () async -> Void
  let onReport: (FeedReportType) async -> Void

  @State private var showPopover: Bool = false

  var body: some View {
    HStack {
      FeedAuthorAvatar(url: profileImageURL)

      Group {
        if isAuthor {
          Text(authorName + " (\(authorTagText))")
            .foregroundStyle(.tint)
        } else {
          Text(authorName)
        }
      }
      .fontWeight(.semibold)
      .font(.callout)

      if isKaistIP {
        Image(systemName: "checkmark.seal.fill")
          .foregroundStyle(.tint)
          .scaleEffect(0.9)
          .popover(isPresented: $showPopover) {
            Text("This post was created from within the KAIST network.", bundle: .module)
              .frame(width: 200)
              .presentationCompactAdaptation(.popover)
              .padding()
          }
          .onTapGesture {
            showPopover = true
          }
          .accessibilityLabel(Text("This post was created from within the KAIST network.", bundle: .module))
      }

      Text(timeText)
        .foregroundStyle(.secondary)
        .font(.callout)

      Spacer()

      if downvotes >= 15 && !isHiddenCommentExpanded && !showFullContent {
        Button(String(localized: "Expand", bundle: .module), systemImage: "chevron.right") {
          isHiddenCommentExpanded = true
        }
        .labelStyle(.iconOnly)
        .padding(8)
        .tint(.secondary)
      } else {
        Menu {
          Button(String(localized: "Translate", bundle: .module), systemImage: "translate") { onTranslate() }
          Divider()
          if isMyComment {
            Button(String(localized: "Delete", bundle: .module), systemImage: "trash", role: .destructive) {
              Task {
                await onDelete()
              }
            }
          } else {
            Menu(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle.fill") {
              ForEach(FeedReportType.allCases) { reason in
                Button(reason.description) {
                  Task {
                    await onReport(reason)
                  }
                }
              }
            }
          }
        } label: {
          Label(String(localized: "More", bundle: .module), systemImage: "ellipsis")
            .labelStyle(.iconOnly)
            .padding(8)
            .contentShape(.rect)
        }
      }
    }
  }
}
