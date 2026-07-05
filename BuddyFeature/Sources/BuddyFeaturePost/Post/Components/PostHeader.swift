//
//  PostHeader.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI

/// Title, metadata (date/views), and the tappable author row.
struct PostHeader: View {
  let title: AttributedString
  let createdAtText: String
  let views: Int
  let authorProfileURL: URL?
  let authorNickname: String
  let isAnonymous: Bool
  let onAuthorTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)

      HStack {
        Text(createdAtText)
        Text("\(views) views", bundle: .module)
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      Button(action: onAuthorTapped) {
        HStack {
          PostAuthorAvatar(url: authorProfileURL, size: 28)

          Text(authorNickname)
            .fontWeight(.medium)

          if !isAnonymous {
            Image(systemName: "chevron.right")
          }
        }
        .font(.subheadline)
      }
      .tint(.primary)
      .disabled(isAnonymous)

      Divider()
        .padding(.vertical, 4)
    }
  }
}
