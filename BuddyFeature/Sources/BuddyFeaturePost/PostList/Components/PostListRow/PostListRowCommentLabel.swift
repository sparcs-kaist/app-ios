//
//  PostListRowCommentLabel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI

struct PostListRowCommentLabel: View {
  let commentCount: Int

  var body: some View {
    Group {
      if commentCount > 0 {
        HStack(spacing: 4) {
          Image(systemName: "bubble")
            .scaleEffect(0.9)
          Text("\(commentCount)")
        }
        .foregroundStyle(.primary)
      }
    }
  }
}

#Preview {
  PostListRowCommentLabel(commentCount: 10)
}
