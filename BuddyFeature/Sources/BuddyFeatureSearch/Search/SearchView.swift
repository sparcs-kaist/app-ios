//
//  SearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import BuddyFeatureTimetable
import BuddyFeaturePost
import BuddyFeatureTaxi
import FirebaseAnalytics

public struct SearchView: View {
  @State private var viewModel = SearchViewModel()
  @State private var selectedRoom: TaxiRoom? = nil
//  @State private var selectedCourse: Course? = nil
  @State private var courseSheetDetent: PresentationDetent = .height(200)
  @State private var showDepartmentPicker: Bool = false
  @FocusState private var isFocused

  public init() { }

  public var body: some View {
    Group {
      if case let .error(message) = viewModel.state {
        ContentUnavailableView(
          message,
          systemImage: "exclamationmark.circle",
          description: Text("Please try again later.", bundle: .module)
        )
      } else if !viewModel.hasCriteria {
        if viewModel.searchScope == .courses {
          ContentUnavailableView(
            String(localized: "Search Courses", bundle: .module),
            systemImage: "magnifyingglass",
            description: Text("Search by name, code or professor, or browse with filters.", bundle: .module)
          )
        } else {
          ContentUnavailableView(
            "Search Anything",
            systemImage: "magnifyingglass",
            description: Text("Find courses, posts, rides and more.", bundle: .module)
          )
        }
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
      VStack(spacing: 8) {
        Picker(String(localized: "Search Scope", bundle: .module), selection: $viewModel.searchScope) {
          ForEach(SearchScope.allCases) { scope in
            Text(scope.description).tag(scope)
          }
        }
        .pickerStyle(.segmented)
        .glassEffect(.regular.interactive(), in: ContainerRelativeShape())
        .padding(.horizontal)

        // Course filters only apply in the Courses scope, so that is where they are offered.
        if viewModel.searchScope == .courses {
          CourseFilterBar(
            filter: $viewModel.courseFilter,
            period: $viewModel.coursePeriod,
            selectedDepartments: viewModel.selectedDepartments,
            onSelectDepartments: { showDepartmentPicker = true }
          )
          .transition(.opacity)
        }
      }
      .contentWidth()
      .animation(.snappy, value: viewModel.searchScope)
    }
    .searchable(text: $viewModel.searchText, prompt: Text("Search", bundle: .module))
    .searchFocused($isFocused)
    .navigationDestination(for: CourseSummary.self) { course in
      CourseView(course: course)
    }
    .navigationDestination(for: AraPost.self) { post in
      PostView(post: post)
        .toolbar(.hidden, for: .tabBar)
    }
    // A sheet rather than a push: the search tab only shows a search field for its root view,
    // and the department list needs its own.
    .sheet(isPresented: $showDepartmentPicker) {
      NavigationStack {
        DepartmentPicker(
          departments: viewModel.departments,
          interestedDepartmentIDs: viewModel.interestedDepartmentIDs,
          state: viewModel.departmentState,
          selection: $viewModel.courseFilter.departmentIDs,
          onRetry: { await viewModel.fetchDepartments() }
        )
        // Picks up interested departments changed in Settings since the tab first appeared.
        .task {
          await viewModel.fetchDepartments()
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              showDepartmentPicker = false
            }
          }
        }
      }
      .presentationDragIndicator(.visible)
    }
    .task {
      await viewModel.fetchDepartments()
    }
    .analyticsScreen(name: "Search", class: String(describing: Self.self))
  }
  
  private func courseSection(courses: [CourseSummary]) -> some View {
    SearchSection(title: String(localized: "Courses", bundle: .module), searchScope: $viewModel.searchScope, targetScope: .courses) {
      SearchContent(results: courses) { course in
        NavigationLink(value: course) {
          CourseCell(course: course)
        }
        .foregroundStyle(.primary)
        .redacted(reason: viewModel.state == .loading ? .placeholder : [])
        .disabled(viewModel.state == .loading)
      } onLoadMore: {
        if viewModel.searchScope == .courses {
          await viewModel.loadCoursesNextPage()
        }
      }
    }
  }
  
  private func postSection(posts: [AraPost]) -> some View {
    SearchSection(title: String(localized: "Posts", bundle: .module), searchScope: $viewModel.searchScope, targetScope: .posts) {
      SearchContent(results: posts) { post in
        NavigationLink(value: post) {
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
    SearchSection(title: String(localized: "Rides", bundle: .module), searchScope: $viewModel.searchScope, targetScope: .taxi) {
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
          courseSection(courses: viewModel.state == .loading ? Array(CourseSummary.mockList.prefix(3)) : Array(viewModel.courses.prefix(3)))
        } else if viewModel.searchScope == .courses {
          courseSection(courses: viewModel.state == .loading ? CourseSummary.mockList : viewModel.courses)
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
      .contentWidth()
      .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
    .scrollDismissesKeyboard(.immediately)
    .toolbarTitleDisplayMode(.inlineLarge)
  }
}

#Preview {
  SearchView()
}
