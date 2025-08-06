//
//  PostCommentButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI


struct PostCommentButton: View {
  let commentCount: Int

  var body: some View {
    HStack {
      Button("comments", systemImage: "text.bubble") {

      }
      .labelStyle(.iconOnly)
      .foregroundStyle(.primary)

      Text("\(commentCount)")
    }
    .padding(8)
    .glassEffect(.regular.interactive())
  }
}
