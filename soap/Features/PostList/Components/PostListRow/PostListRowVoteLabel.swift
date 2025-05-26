//
//  PostListRowVoteLabel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI

/// PostListRowVoteLabel
/// requires voteCount: Int
/// displays number of votes with arrows. does not show anything when the voteCount == 0
struct PostListRowVoteLabel: View {
  let voteCount: Int

  var body: some View {
    Group {
      if voteCount > 0 {
        // upvoted

        HStack(spacing: 4) {
          Image(systemName: "arrowshape.up.fill")
          Text("\(voteCount)")
            .lineLimit(1)
        }
        .foregroundStyle(Color(hex: "ff4500"))
      } else if voteCount < 0 {
        // downvoted
        HStack(spacing: 4) {
          Image(systemName: "arrowshape.down.fill")
          Text("\(voteCount)")
            .lineLimit(1)
        }
        .foregroundStyle(Color(hex: "047dff"))
      }
    }
  }
}

#Preview {
  PostListRowVoteLabel(voteCount: 10)
  PostListRowVoteLabel(voteCount: -10)
}
