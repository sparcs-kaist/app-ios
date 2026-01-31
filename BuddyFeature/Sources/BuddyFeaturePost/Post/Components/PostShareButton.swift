//
//  PostShareButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI


struct PostShareButton: View {
  let url: URL
  
  var body: some View {
    ShareLink(item: url) {
      Label("share", systemImage: "square.and.arrow.up")
    }
    .labelStyle(.iconOnly)
    .foregroundStyle(.primary)
    .padding(8)
    .glassEffect(.regular.interactive(), in: .circle)
  }
}
