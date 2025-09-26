//
//  SearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import SwiftUI

struct SearchView: View {
  @State private var searchText: String = ""

  var body: some View {
    NavigationStack {
      Group {
        
      }
      .navigationTitle("Search")
      .toolbarTitleDisplayMode(.inlineLarge)
    }
    .searchable(text: $searchText, prompt: Text("Search anything..."))
  }
}

#Preview {
  SearchView()
}
