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
          ZStack {
            Color.secondarySystemBackground.ignoresSafeArea()
            resultView
          }
        }
      }
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
  
  private var resultView: some View {
    ScrollView {
      // TODO: Courses Search
      
      SearchSection(title: "Posts", content: {
        SearchContent(results: AraPost.mockList[..<3]) {
          PostListRow(post: $0)
            .padding()
        }
      }, destination: {
      })
      
      SearchSection(title: "Rides", content: {
        SearchContent(results: TaxiRoom.mockList[..<3]) {
          TaxiRoomCell(room: $0)
        }
      }, destination: {
        TaxiListView()
      })
      
      Spacer()
    }
    .navigationTitle("Search")
    .toolbarTitleDisplayMode(.inlineLarge)
  }
}

#Preview {
  SearchView()
}
