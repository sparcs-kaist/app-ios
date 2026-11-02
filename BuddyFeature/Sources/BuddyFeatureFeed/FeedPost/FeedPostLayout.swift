//
//  FeedPostLayout.swift
//  BuddyFeature
//

import SwiftUI

/// Both panes fit on either side of a folded iPhone Duo.
enum FeedPostPaneWidth {
  static let post: CGFloat = 380
  static let comments: CGFloat = 320
}

struct FeedPostPanes<Post: View, Comments: View>: View {
  @ViewBuilder let post: Post
  @ViewBuilder let comments: Comments

  @Environment(\.displayScale) private var displayScale

  var body: some View {
    if #available(iOS 27.1, *) {
      ArrangementView {
        post
          .splitArrangementLayoutSize(minWidth: FeedPostPaneWidth.post, idealWidth: 560)
      } secondary: {
        comments
          .overlay(alignment: .leading) {
            Rectangle()
              .fill(.separator)
              .frame(width: 1 / displayScale)
              .ignoresSafeArea(edges: .vertical)
          }
          .splitArrangementLayoutSize(minWidth: FeedPostPaneWidth.comments)
      }
      .arrangementViewStyle(.split.axes(.horizontal))
    } else {
      HStack(spacing: 0) {
        post
          .frame(minWidth: FeedPostPaneWidth.post, maxWidth: .infinity)
          .layoutPriority(1)
        Divider()
        comments
          .frame(minWidth: FeedPostPaneWidth.comments, maxWidth: 420)
      }
    }
  }
}

/// Scrolling comments should not collapse the navigation bar over the post.
struct FeedPostNavigationBar: ViewModifier {
  let isPinned: Bool

  func body(content: Content) -> some View {
    if #available(iOS 27.0, *), isPinned {
      content.toolbarMinimizationBehavior(.never, for: .navigationBar)
    } else {
      content
    }
  }
}
