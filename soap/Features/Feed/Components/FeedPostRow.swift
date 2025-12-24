//
//  FeedPostRow.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import NukeUI
import Factory
import BuddyDomain

struct FeedPostRow: View {
  @Binding var post: FeedPost
  let onPostDeleted: ((String) -> Void)?
  let onComment: (() -> Void)?
  @State var showFullContent: Bool = false

  @State private var showAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""
  @State private var canBeExpanded: Bool = false
  
  @State private var showDeleteConfirmation: Bool = false
  @State private var showTranslateSheet: Bool = false
  @State private var showPopover: Bool = false

  // MARK: - Dependencies
  @Injected(\.feedPostRepository) private var feedPostRepository: FeedPostRepositoryProtocol
  @ObservationIgnored @Injected(\.crashlyticsHelper) private var crashlyticsHelper: CrashlyticsHelper

  var body: some View {
    Group {
      VStack(alignment: .leading) {
        header

        content

        footer
      }
    }
    .translationPresentation(isPresented: $showTranslateSheet, text: post.content)
  }

  @ViewBuilder
  var profileImage: some View {
    if let url = post.profileImageURL {
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
      .frame(width: 24, height: 24)
      .clipShape(.circle)
    } else {
      Circle()
        .fill(Color.secondarySystemBackground)
        .frame(width: 24, height: 24)
        .overlay {
          Text("😀")
            .font(.caption)
        }
    }
  }

  var header: some View {
    HStack {
      profileImage

      Text(post.authorName)
        .fontWeight(.semibold)
        .font(.callout)
      
      if post.isKaistIP {
        Image(systemName: "checkmark.seal.fill")
          .foregroundStyle(Color(.systemBlue))
          .scaleEffect(0.9)
          .popover(isPresented: $showPopover) {
            Text("KAIST IP verified")
              .presentationCompactAdaptation(.popover)
              .padding()
          }
          .onTapGesture {
            showPopover = true
          }
          .accessibilityLabel(Text("KAIST IP verified"))
      }

      // onPostDeleted == nil here means FeedPostRow is in the FeedPostView.
      Text(onPostDeleted != nil ? post.createdAt.timeAgoDisplay : post.createdAt.relativeTimeString)
        .foregroundStyle(.secondary)
        .font(.callout)

      Spacer()

      if onPostDeleted != nil {
        Menu("More", systemImage: "ellipsis") {
          Button("Translate", systemImage: "translate") { showTranslateSheet = true }
          Divider()
          if post.isAuthor {
            Button("Delete", systemImage: "trash", role: .destructive) {
              showDeleteConfirmation = true
            }
          } else {
            Menu("Report", systemImage: "exclamationmark.triangle.fill") {
              ForEach(FeedReportType.allCases) { reason in
                Button(reason.description) {
                  Task {
                    do {
                      try await feedPostRepository.reportPost(postID: post.id, reason: reason, detail: "")
                      showAlert(title: String(localized: "Report Submitted"), message: String(localized: "Your report has been submitted successfully."))
                    } catch {
                      crashlyticsHelper.recordException(error: error, showAlert: false)
                      showAlert(title: String(localized: "Error"), message: String(localized: "An unexpected error occurred while reporting a post. Please try again later."))
                    }
                  }
                }
              }
            }
          }
        }
        .labelStyle(.iconOnly)
        .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
          Button("Delete", role: .destructive) {
            Task {
              onPostDeleted?(post.id)
            }
          }
          Button("Cancel", role: .cancel) { }
        } message: {
          Text("Are you sure you want to delete this post?")
        }
        .alert(alertTitle, isPresented: $showAlert, actions: {
          Button("Okay", role: .close) { }
        }, message: {
          Text(alertMessage)
        })
      }
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  var content: some View {
    Text(post.content)
      .textSelection(.enabled)
      .padding(.horizontal)
      .lineLimit(showFullContent ? nil : 5)
      .background {
        ViewThatFits(in: .vertical) {
          Text(post.content)
            .hidden()
          Color.clear.onAppear {
            canBeExpanded = true
          }
        }
      }
    if canBeExpanded && !showFullContent {
      Button("more") {
        withAnimation {
          showFullContent = true
        }
      }
      .padding(.horizontal)
      .foregroundStyle(.secondary)
    }
    if !post.images.isEmpty {
      PostImagesStrip(images: post.images)
    }
  }

  var footer: some View {
    HStack {
      PostVoteButton(
        myVote: post.myVote == .up ? true : post.myVote == .down ? false : nil,
        votes: post.upvotes - post.downvotes,
        onDownvote: {
          await downvote()
        }, onUpvote: {
          await upvote()
        }
      )

      PostCommentButton(commentCount: post.commentCount) {
        onComment?()
      }
      .allowsHitTesting(onComment != nil)

      Spacer()

//      if onPostDeleted == nil {
//        PostShareButton(url: URL(string: "https://sparcs.org")!) // FIXME: Feed URL Placeholder
//      }
    }
    .frame(height: 20)
    .padding(.horizontal)
    .padding(.top, 4)
  }

  // MARK: - Functions
  private func upvote() async {
    let previousMyVote: FeedVoteType? = post.myVote
    let previousUpvotes: Int = post.upvotes

    do {
      if previousMyVote == .up {
        // cancel upvote
        post.myVote = nil
        post.upvotes -= 1
        try await feedPostRepository.deleteVote(postID: post.id)
      } else {
        // upvote
        if previousMyVote == .down {
          // remove downvote if there was
          post.downvotes -= 1
        }
        post.myVote = .up
        post.upvotes += 1
        try await feedPostRepository.vote(postID: post.id, type: .up)
      }
    } catch {
      logger.error(error)
      post.myVote = previousMyVote
      post.upvotes = previousUpvotes
    }
  }

  private func downvote() async {
    let previousMyVote: FeedVoteType? = post.myVote
    let previousDownvotes: Int = post.downvotes

    do {
      if previousMyVote == .down {
        // cancel downvote
        post.myVote = nil
        post.downvotes -= 1
        try await feedPostRepository.deleteVote(postID: post.id)
      } else {
        // downvote
        if previousMyVote == .up {
          // remove downvote if there was
          post.upvotes -= 1
        }
        post.myVote = .down
        post.downvotes += 1
        try await feedPostRepository.vote(postID: post.id, type: .down)
      }
    } catch {
      logger.error(error)
      post.myVote = previousMyVote
      post.downvotes = previousDownvotes
    }
  }
  
  private func showAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showAlert = true
  }
}

#Preview {
  FeedPostRow(post: .constant(FeedPost.mock), onPostDeleted: nil, onComment: nil)
}
