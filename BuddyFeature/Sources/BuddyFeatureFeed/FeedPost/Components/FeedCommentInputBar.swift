//
//  FeedCommentInputBar.swift
//  BuddyFeature
//
//  Created by Jungwoo Ha on 04/10/2026.
//

import SwiftUI
import BuddyDomain

/// The comment composer pinned below a comment list: an optional reply
/// preview, the text field, the anonymity toggle, and the send button.
struct FeedCommentInputBar: View {
  @Binding var text: String
  @Binding var isAnonymous: Bool
  @Binding var targetComment: FeedComment?
  var isFocused: FocusState<Bool>.Binding
  let isSubmitting: Bool
  let onSubmit: () -> Void

  var body: some View {
    HStack(alignment: .bottom) {
      // comment textfield
      VStack(alignment: .leading) {
        if let targetComment {
          FeedCommentReplyPreview(
            authorName: targetComment.authorName,
            content: targetComment.content,
            isDeleted: targetComment.isDeleted,
            onCancel: { self.targetComment = nil }
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        // maybe some images and anonymous selector
        TextField(
          text: $text,
          prompt: Text(
            targetComment != nil
              ? String(localized: "Write a reply to \(targetComment?.authorName ?? String(localized: "unknown", bundle: .module))", bundle: .module)
              : String(localized: "Write a comment", bundle: .module)
          ),
          axis: .vertical,
          label: {
          }
        )
        // Grows with the comment, but stops short of pushing the post off a
        // short screen; longer text scrolls within the field.
        .lineLimit(1...5)
        .focused(isFocused)

        if isFocused.wrappedValue {
          Toggle(String(localized: "Write Anonymously", bundle: .module), isOn: $isAnonymous)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .fontDesign(.rounded)
            .font(.callout)
            .fontWeight(.medium)
        }
      }
      .padding(12)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))

      // write comment button
      if !text.isEmpty {
        Button(action: {
          guard !text.isEmpty else { return }
          onSubmit()
        }, label: {
          Group {
            if isSubmitting {
              ProgressView()
                .tint(.white)
            } else {
              Label(String(localized: "Send", bundle: .module), systemImage: "paperplane")
                .labelStyle(.iconOnly)
                .tint(.white)
            }
          }
          .padding(12)
          .contentShape(.circle)
        })
        .fontWeight(.medium)
        .glassEffect(.regular.tint(Color.accentColor).interactive(), in: .circle)
        .disabled(text.isEmpty || isSubmitting)
        .transition(.move(edge: .trailing).combined(with: .opacity))
      }
    }
    .padding(isFocused.wrappedValue ? [.horizontal, .vertical] : [.horizontal])
    .contentWidth()
    .animation(.spring, value: isFocused.wrappedValue)
    .animation(.spring, value: targetComment?.id)
    .animation(
      .spring(duration: 0.35, bounce: 0.4, blendDuration: 0.15),
      value: text.isEmpty
    )
  }
}
