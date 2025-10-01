//
//  HomeView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI
import Factory

struct HomeView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 27) {
          BoardRecentSection(title: "Trending")

          TaxiRecentSection()

          BoardsSection()

          BoardRecentSection(title: "General")

          BoardRecentSection(title: "Notice")
        }
        .padding(.vertical)
      }
      .background(Color.secondarySystemBackground)
    }
  }
}

#Preview {
  HomeView()
}
