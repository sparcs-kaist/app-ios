//
//  PostCommentButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI
import Haptica


struct PostCommentButton: View {
  let commentCount: Int
  let onClick: () -> Void

  var body: some View {
    Button("\(commentCount)", systemImage: "text.bubble") {
      Haptic.impact(.light).generate()
      onClick()
    }
    .animation(.spring(), value: commentCount)
    .contentTransition(.numericText(value: Double(commentCount)))
    .tint(.primary)
    .padding(8)
    .glassEffect(.regular.interactive())
  }
}
