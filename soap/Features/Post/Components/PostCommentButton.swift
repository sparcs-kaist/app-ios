//
//  PostCommentButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI


struct PostCommentButton: View {
  var body: some View {
    HStack {
      Button("comments", systemImage: "text.bubble") {

      }
      .labelStyle(.iconOnly)
      .foregroundStyle(.primary)

      Text("23")
    }
    .padding(8)
    .glassEffect(.regular.interactive())
  }
}
