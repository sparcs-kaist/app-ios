//
//  PostCommentButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI


struct PostCommentButton: View {
  let commentCount: Int
  let onClick: () -> Void

  var body: some View {
    HStack {
      Button("comments", systemImage: "text.bubble") {
        onClick()
      }
      .labelStyle(.iconOnly)
      .foregroundStyle(.primary)

      Text("\(commentCount)")
        .animation(.spring(), value: commentCount)
        .contentTransition(.numericText(value: Double(commentCount)))
    }
    .padding(8)
    .glassEffect(.regular.interactive())
  }
}
