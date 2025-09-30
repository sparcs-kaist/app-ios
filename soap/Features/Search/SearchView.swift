//
//  SearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import SwiftUI

struct SearchView: View {
  @State private var viewModel = SearchViewModel()
  @State private var selectedRoom: TaxiRoom? = nil
  @State private var selectedCourse: Course? = nil
  @State private var courseSheetDetent: PresentationDetent = .height(200)
  @FocusState private var isFocused

  var body: some View {
    NavigationStack {
      ZStack {
        Color.secondarySystemBackground.ignoresSafeArea()
        
        Group {
          switch viewModel.state {
          case .loading:
            VStack {
              Spacer().frame(height: 50)
              SearchSection(title: "Courses", searchScope: $viewModel.searchScope, targetScope: .taxi) {
                SearchContent(results: Course.mockList) {
                  CourseCell(course: $0)
                }
              }
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
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
      }
      .overlay {
        VStack {
          Picker("Search Scope", selection: $viewModel.searchScope) {
            ForEach(SearchScope.allCases) { scope in
              Text(scope.rawValue).tag(scope)
            }
          }
          .pickerStyle(.segmented)
          .glassEffect(.regular.interactive(), in: ContainerRelativeShape())
          .padding(.horizontal)
          Spacer()
        }
        .opacity(hideScopeBar ? 0 : 1)
        .disabled(hideScopeBar)
      }
    }
    .searchable(text: $viewModel.searchText, prompt: Text("Search"))
    .searchFocused($isFocused)
    .task {
      viewModel.bind()
    }
  }
  
  private func courseSection(courses: [Course]) -> some View {
    SearchSection(title: "Courses", searchScope: $viewModel.searchScope, targetScope: .courses) {
      SearchContent(results: courses) { course in
        NavigationLink {
          CourseView(course: course)
        } label: {
          CourseCell(course: course)
        }
        .foregroundStyle(.primary)
      }
    }
  }
  
  private func postSection(posts: [AraPost]) -> some View {
    SearchSection(title: "Posts", searchScope: $viewModel.searchScope, targetScope: .posts) {
      SearchContent(results: posts) { post in
        NavigationLink(destination: {
          PostView(post: post)
            .toolbar(.hidden, for: .tabBar)
        }) {
          PostListRow(post: post)
        }
        .foregroundStyle(.primary)
        .padding()
      } onLoadMore: {
        if viewModel.searchScope == .posts {
          Task {
            await viewModel.loadAraNextPage()
          }
        }
      }
    }
  }
  
  private func taxiSection(rooms: [TaxiRoom]) -> some View {
    SearchSection(title: "Rides", searchScope: $viewModel.searchScope, targetScope: .taxi) {
      SearchContent(results: rooms) { room in
        TaxiRoomCell(room: room)
          .onTapGesture {
            selectedRoom = room
          }
      }
    }
    .sheet(item: $selectedRoom) {
      Task {
        await viewModel.scopedFetch()
      }
    } content: {
      TaxiPreviewView(room: $0)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(400), .height(500)])
    }
  }
  
  private func resultView(courses: [Course], posts: [AraPost], rooms: [TaxiRoom]) -> some View {
    ScrollView {
      Spacer().frame(height: 50)
      Group {
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
      .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
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
  
  private var hideScopeBar: Bool {
    return viewModel.searchText.isEmpty
  }
}

#Preview {
  SearchView()
}
