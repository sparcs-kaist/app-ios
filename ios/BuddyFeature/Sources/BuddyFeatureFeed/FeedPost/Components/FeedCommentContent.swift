//
//  FeedCommentContent.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// Comment body text (with expand affordance) or the deleted placeholder.
struct FeedCommentContent: View {
  let content: String
  let isDeleted: Bool
  @Binding var showFullContent: Bool
  let onOpenURL: (URL) -> OpenURLAction.Result

  @State private var canBeExpanded: Bool = false

  var body: some View {
    Group {
      if isDeleted {
        Text("This comment has been deleted.", bundle: .module)
      } else {
        Text(content.toDetectedAttributedString())
      }
    }
    .lineLimit(showFullContent ? nil : 3)
    .textSelection(.enabled)
    .foregroundStyle(isDeleted ? .secondary : .primary)
    .contentTransition(.numericText())
    .animation(.spring, value: isDeleted)
    .background {
      ViewThatFits(in: .vertical) {
        Text(content)
          .hidden()

        Color.clear.onAppear {
          canBeExpanded = true
        }
      }
    }
    .environment(\.openURL, OpenURLAction(handler: onOpenURL))

    if canBeExpanded && !showFullContent && !isDeleted {
      Button(String(localized: "more", bundle: .module)) {
        withAnimation {
          showFullContent = true
        }
      }
      .foregroundStyle(.secondary)
    }
  }
}
