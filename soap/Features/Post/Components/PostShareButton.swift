//
//  PostShareButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI


struct PostShareButton: View {
  var body: some View {
    Button("share", systemImage: "square.and.arrow.up") {

    }
    .labelStyle(.iconOnly)
    .foregroundStyle(.primary)
    .padding(8)
    .glassEffect(.regular.interactive(), in: .circle)
  }
}
