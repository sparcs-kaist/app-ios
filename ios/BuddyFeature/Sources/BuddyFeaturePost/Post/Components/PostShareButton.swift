//
//  PostShareButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import Foundation
import SwiftUI


struct PostShareButton: View {
  let url: URL
  
  var body: some View {
    ShareLink(item: url) {
      Label(String(localized: "share", bundle: .module), systemImage: "square.and.arrow.up")
    }
    .labelStyle(.iconOnly)
    .foregroundStyle(.primary)
    .padding(8)
    .glassEffect(.regular.interactive(), in: .circle)
  }
}
