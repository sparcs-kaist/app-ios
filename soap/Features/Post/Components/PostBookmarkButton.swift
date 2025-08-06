//
//  PostBookmarkButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI


struct PostBookmarkButton: View {
  var body: some View {
    Button("bookmark", systemImage: "bookmark") {

    }
    .labelStyle(.iconOnly)
    .foregroundStyle(.primary)
    .padding(8)
    .glassEffect(.regular.interactive(), in: .circle)
  }
}
