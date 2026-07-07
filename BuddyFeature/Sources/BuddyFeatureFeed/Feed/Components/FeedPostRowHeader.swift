//
//  FeedPostRowHeader.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import BuddyDomain

/// Author, verification badge, timestamp, and the more/expand controls.
struct FeedPostRowHeader: View {
  let profileImageURL: URL?
  let authorName: String
  let isKaistIP: Bool
  let timeText: String
  let downvotes: Int
  let isAuthor: Bool
  let isFeedContext: Bool
  let showFullContent: Bool
  @Binding var isHiddenPostExpanded: Bool
  let onTranslate: () -> Void
  let onReport: (FeedReportType) async -> Void
  let onDelete: () -> Void

  @State private var showPopover: Bool = false
  @State private var showDeleteConfirmation: Bool = false

  var body: some View {
    HStack {
      FeedAuthorAvatar(url: profileImageURL)

      Text(authorName)
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

      if downvotes >= 15 && !isHiddenPostExpanded && !showFullContent {
        Button(String(localized: "Expand", bundle: .module), systemImage: "chevron.right") {
          isHiddenPostExpanded = true
        }
        .labelStyle(.iconOnly)
        .padding(8)
        .tint(.secondary)
      } else if isFeedContext {
        Menu {
          Button(String(localized: "Translate", bundle: .module), systemImage: "translate") { onTranslate() }
          Divider()
          if isAuthor {
            Button(String(localized: "Delete", bundle: .module), systemImage: "trash", role: .destructive) {
              showDeleteConfirmation = true
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
        .confirmationDialog(String(localized: "Delete Post", bundle: .module), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
          Button(String(localized: "Delete", bundle: .module), role: .destructive) {
            onDelete()
          }
          Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
        } message: {
          Text("Are you sure you want to delete this post?", bundle: .module)
        }
      }
    }
    .padding(.horizontal)
  }
}
