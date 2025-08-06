//
//  PostView.swift
//  soap
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI
import NukeUI

struct PostView: View {
  let post: AraPost

  @State private var htmlHeight: CGFloat = .zero
  @State private var comment: String = ""
  @FocusState private var isWritingCommentFocusState: Bool
  @State private var isWritingComment: Bool = false

  var body: some View {
    ScrollView {
      Group {
        header

        content

        footer

        comments
      }
      .padding()
    }
    .scrollDismissesKeyboard(.interactively)
    .contentMargins(.bottom, 64)
    .safeAreaBar(edge: .bottom) {
      HStack {
        HStack {
          if !isWritingComment && comment.isEmpty {
            Circle()
              .frame(width: 21, height: 21)
              .transition(.move(edge: .leading).combined(with: .opacity))
          }

          TextField(text: $comment, prompt: Text("reply as anonymous"), label: {})
            .focused($isWritingCommentFocusState)
        }
        .padding(12)
        .glassEffect(.clear.interactive())
        .tint(.primary)

        if !comment.isEmpty {
          Button("send", systemImage: "paperplane") { }
            .fontWeight(.medium)
            .labelStyle(.iconOnly)
            .tint(.white)
            .padding(12)
            .glassEffect(.regular.tint(.black).interactive(), in: .circle)
            .disabled(comment.isEmpty)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
      }
      .padding()
      .animation(
        .spring(duration: 0.35, bounce: 0.4, blendDuration: 0.15),
        value: comment.isEmpty
      )
      .animation(
        .spring(duration: 0.2, bounce: 0.2, blendDuration: 0.1),
        value: isWritingComment
      )
    }
    .onChange(of: isWritingCommentFocusState) {
      isWritingComment = isWritingCommentFocusState
    }
  }

  private var comments: some View {
    VStack(spacing: 16) {
      // Main comment
      VStack(alignment: .leading, spacing: 8) {
        Divider()

        HStack {
          Circle()
            .frame(width: 21, height: 21)

          Text("anonymous")
            .fontWeight(.medium)

          Text("22 May 17:44")
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()

          Button("more", systemImage: "ellipsis") { }
            .labelStyle(.iconOnly)
        }
        .font(.callout)

        Text("배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 ")
          .font(.callout)

        HStack {
          Spacer()

          PostCommentButton()
            .fixedSize()

          PostVoteButton()
            .fixedSize()
        }
        .font(.caption)

        // Threads
        HStack(alignment: .top, spacing: 8) {
          Image(systemName: "arrow.turn.down.right")

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Circle()
                .frame(width: 21, height: 21)

              Text("anonymous")
                .fontWeight(.medium)

              Text("22 May 17:44")
                .font(.caption)
                .foregroundStyle(.secondary)

              Spacer()

              Button("more", systemImage: "ellipsis") { }
                .labelStyle(.iconOnly)
            }
            .font(.callout)

            Text("배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 ")
              .font(.callout)

            HStack {
              Spacer()

              PostVoteButton()
                .fixedSize()
            }
            .font(.caption)
          }
        }

        HStack(alignment: .top, spacing: 8) {
          Image(systemName: "arrow.turn.down.right")

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Circle()
                .frame(width: 21, height: 21)

              Text("anonymous")
                .fontWeight(.medium)

              Text("22 May 17:44")
                .font(.caption)
                .foregroundStyle(.secondary)

              Spacer()

              Button("more", systemImage: "ellipsis") { }
                .labelStyle(.iconOnly)
            }
            .font(.callout)

            Text("aaaa")
              .font(.callout)

            HStack {
              Spacer()

              PostVoteButton()
                .fixedSize()
            }
            .font(.caption)
          }
        }
      }

      // Main comment
      VStack(alignment: .leading, spacing: 8) {
        Divider()

        HStack {
          Circle()
            .frame(width: 21, height: 21)

          Text("anonymous")
            .fontWeight(.medium)

          Text("22 May 17:44")
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()

          Button("more", systemImage: "ellipsis") { }
            .labelStyle(.iconOnly)
        }
        .font(.callout)

        Text("배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 배고픈데 뭐먹을지 추천 좀 ")
          .font(.callout)

        HStack {
          Spacer()

          PostCommentButton()
            .fixedSize()

          PostVoteButton()
            .fixedSize()
        }
        .font(.caption)
      }
    }
    .padding(.top, 4)
  }

  private var footer: some View {
    HStack {
      PostVoteButton()

      PostCommentButton()

      Spacer()

      PostBookmarkButton()

      PostShareButton()
    }
    .font(.callout)
  }

  @ViewBuilder
  private var content: some View {
//    HTMLView(contentHeight: $htmlHeight, htmlString: contentString)
//      .frame(height: htmlHeight)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(post.title ?? "Untitled")
        .font(.headline)

      HStack {
        Text(post.createdAt.formattedString)
        Text("\(post.views) views")
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      HStack {
        if let url = post.author.profile.profilePictureURL {
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
          .frame(width: 28, height: 28)
          .clipShape(.circle)
        } else {
          Circle()
            .fill(Color.secondarySystemBackground)
            .frame(width: 28, height: 28)
        }

        Text(post.author.profile.nickname)
          .fontWeight(.medium)

        Image(systemName: "chevron.right")
      }
      .font(.subheadline)

      Divider()
        .padding(.vertical, 4)
    }
  }
}

#Preview {
  NavigationStack {
    PostView(post: AraPost.mock)
  }
}
