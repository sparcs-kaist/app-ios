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
      ZStack {
        Color.secondarySystemBackground.ignoresSafeArea()
        
        Group {
          switch viewModel.state {
          case .loading:
            VStack {
              SearchSection(title: "Courses", content: {
                SearchContent(results: Course.mockList) {
                  CourseCell(course: $0)
                }
              }, destination: {
                
              })
              Spacer()
            }
            .redacted(reason: .placeholder)
          case .loaded(let courses, let posts, let rooms):
            Group {
              if viewModel.searchText.isEmpty {
                ContentUnavailableView("Search Anything", systemImage: "magnifyingglass", description: Text("Find courses, posts, rides and more."))
              } else {
                resultView(courses: courses, posts: posts, rooms: rooms)
              }
            }
          case .error(let message):
            ContentUnavailableView(message, systemImage: "exclamationmark.circle", description: Text("Please try again later."))
          }
        }.transition(.opacity.animation(.easeInOut(duration: 0.3)))
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
    .task {
      viewModel.bind()
    }
  }
  
  private func courseSection(courses: [Course]) -> some View {
    SearchSection(title: "Courses", content: {
      SearchContent(results: courses) {
        CourseCell(course: $0)
      }
    }, destination: {
      
    })
  }
  
  private func postSection(posts: [AraPost]) -> some View {
    SearchSection(title: "Posts", content: {
      SearchContent(results: posts) {
        PostListRow(post: $0)
          .padding()
      } onLoadMore: {
        if viewModel.searchScope == .posts {
          Task {
            await viewModel.loadAraNextPage()
          }
        }
      }
    }, destination: {
    })
  }
  
  private func taxiSection(rooms: [TaxiRoom]) -> some View {
    SearchSection(title: "Rides", content: {
      SearchContent(results: rooms) {
        TaxiRoomCell(room: $0)
      }
    }, destination: {
      TaxiListView()
    })
  }
  
  private func resultView(courses: [Course], posts: [AraPost], rooms: [TaxiRoom]) -> some View {
    ScrollView {
      if viewModel.searchScope == .all || viewModel.searchScope == .courses {
        courseSection(courses: courses)
      }
      if viewModel.searchScope == .all || viewModel.searchScope == .posts {
        postSection(posts: posts)
      }
      if viewModel.searchScope == .all || viewModel.searchScope == .taxi {
        taxiSection(rooms: rooms)
      }
    }
    .navigationTitle("Search")
    .toolbarTitleDisplayMode(.inlineLarge)
    .onChange(of: viewModel.searchScope) {
      viewModel.state = .loading
      
      switch viewModel.searchScope {
      case .all:
        if viewModel.searchText.isEmpty {
          return
        }
        Task {
          await viewModel.fetchInitialData()
        }
      default:
        viewModel.loadFull()
      }
    }
  }
}

#Preview {
  SearchView()
}
