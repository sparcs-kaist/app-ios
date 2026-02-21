//
//  FullscreenImageView.swift
//  soap
//
//  Created by Soongyu Kwon on 28/07/2025.
//

import SwiftUI
import NukeUI
import FirebaseAnalytics

struct FullscreenImageView: View {
  let url: URL?

  var body: some View {
    LazyImage(url: url) { state in
      if let image = state.image {
        image
          .resizable()
          .scaledToFit()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ignoresSafeArea()
    .analyticsScreen(name: "Fullscreen Image", class: String(describing: Self.self))
  }
}
