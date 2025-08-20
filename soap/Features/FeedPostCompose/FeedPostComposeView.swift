//
//  FeedPostComposeView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI

struct FeedPostComposeView: View {
  var body: some View {
    NavigationStack {
      VStack {

      }
      .navigationTitle("Write")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") { }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "arrow.up", role: .confirm) { }
        }
      }
    }
  }
}

#Preview {
  FeedPostComposeView()
}
