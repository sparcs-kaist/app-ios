//
//  SearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import SwiftUI

struct SearchView: View {
  @State private var viewModel = SearchViewModel()

  @FocusState private var isFocused

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.searchText.isEmpty {
          ContentUnavailableView("Search Anything", systemImage: "magnifyingglass", description: Text("Find courses, posts, rides and more."))
        } else {
          Text(viewModel.searchScope.rawValue)
        }
      }
      .navigationTitle("Search")
      .toolbarTitleDisplayMode(.inlineLarge)
    }
    .searchable(text: $viewModel.searchText, prompt: Text("Search"))
    .searchScopes($viewModel.searchScope, scopes: {
      ForEach(SearchScope.allCases) { scope in
        Text(scope.rawValue)
          .tag(scope)
      }
    })
    .searchFocused($isFocused)
  }
}

#Preview {
  SearchView()
}
