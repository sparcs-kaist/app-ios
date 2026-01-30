//
//  SearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import BuddyFeatureTimetable
import BuddyFeaturePost
import BuddyFeatureTaxi

struct SearchView: View {
  @State private var viewModel = SearchViewModel()
  @State private var selectedRoom: TaxiRoom? = nil
  @State private var selectedCourse: Course? = nil
  @State private var courseSheetDetent: PresentationDetent = .height(200)
  @FocusState private var isFocused

  var body: some View {
    NavigationStack {
      Group {
        if case let .error(message) = viewModel.state {
          ContentUnavailableView(
            message,
            systemImage: "exclamationmark.circle",
            description: Text("Please try again later.")
          )
        } else if viewModel.searchText.isEmpty {
          ContentUnavailableView(
            "Search Anything",
            systemImage: "magnifyingglass",
            description: Text("Find courses, posts, rides and more.")
          )
        } else {
          resultView
        }
      }
      .background {
        BackgroundGradientView(color: .blue)
          .ignoresSafeArea()
      }
      .background {
        Color.systemGroupedBackground
          .ignoresSafeArea()
      }
      .transition(.opacity.animation(.easeInOut(duration: 0.3)))
      .safeAreaBar(edge: .top) {
        Picker("Search Scope", selection: $viewModel.searchScope) {
          ForEach(SearchScope.allCases) { scope in
            Text(scope.description).tag(scope)
          }
        }
        .pickerStyle(.segmented)
        .glassEffect(.regular.interactive(), in: ContainerRelativeShape())
        .padding(.horizontal)
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
    SearchSection(title: String(localized: "Courses"), searchScope: $viewModel.searchScope, targetScope: .courses) {
      SearchContent(results: courses) { course in
        NavigationLink {
          CourseView(course: course)
        } label: {
          CourseCell(course: course)
        }
        .foregroundStyle(.primary)
        .redacted(reason: viewModel.state == .loading ? .placeholder : [])
        .disabled(viewModel.state == .loading)
      }
    }
  }
  
  private func postSection(posts: [AraPost]) -> some View {
    SearchSection(title: String(localized: "Posts"), searchScope: $viewModel.searchScope, targetScope: .posts) {
      SearchContent(results: posts) { post in
        NavigationLink(destination: {
          PostView(post: post)
            .toolbar(.hidden, for: .tabBar)
        }) {
          PostListRow(post: post)
        }
        .foregroundStyle(.primary)
        .padding()
        .redacted(reason: viewModel.state == .loading ? .placeholder : [])
        .disabled(viewModel.state == .loading)
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
    SearchSection(title: String(localized: "Rides"), searchScope: $viewModel.searchScope, targetScope: .taxi) {
      SearchContent(results: rooms) { room in
        TaxiRoomCell(room: room, withOutBackground: true)
          .onTapGesture {
            selectedRoom = room
          }
          .redacted(reason: viewModel.state == .loading ? .placeholder : [])
          .disabled(viewModel.state == .loading)
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
  
  private var resultView: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        if viewModel.searchScope == .all {
          courseSection(courses: viewModel.state == .loading ? Array(Course.mockList.prefix(3)) : Array(viewModel.courses.prefix(3)))
        } else if viewModel.searchScope == .courses {
          courseSection(courses: viewModel.state == .loading ? Course.mockList : viewModel.courses)
        }

        if viewModel.searchScope == .all {
          postSection(
            posts: viewModel.state == .loading ? Array(AraPost.mockList.prefix(3)) : Array(
              viewModel.posts.prefix(3)
            )
          )
        } else if viewModel.searchScope == .posts {
          postSection(posts: viewModel.state == .loading ? AraPost.mockList : viewModel.posts)
        }

        if viewModel.searchScope == .all {
          taxiSection(
            rooms: viewModel.state == .loading ? Array(TaxiRoom.mockList
              .prefix(3)) : Array(viewModel.taxiRooms
              .prefix(3))
          )
        } else if viewModel.searchScope == .taxi {
          taxiSection(rooms: viewModel.state == .loading ? TaxiRoom.mockList : viewModel.taxiRooms)
        }
      }
      .padding(.top)
      .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
    .scrollDismissesKeyboard(.immediately)
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
