//
//  LectureSearchList.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// The lecture search results with the filter chips and search field beneath them. Shared by
/// the search sheet and the full-screen search, which differ only in what surrounds it.
struct LectureSearchList: View {
  @Bindable var viewModel: LectureSearchViewModel
  /// The timetable being added to, for spotting lectures that are already in it or overlap it.
  let timetable: Timetable?
  let selectedSemester: Semester
  var isSearchFocused: FocusState<Bool>.Binding
  let onOpenLecture: (Lecture) -> Void
  let onOpenCourse: (_ id: Int, _ name: String) -> Void
  let onAddLecture: (Lecture) -> Void
  let onSelectDepartments: () -> Void
  let onChooseTimeOnTimetable: () -> Void

  var body: some View {
    List {
      if !viewModel.hasCriteria {
        if viewModel.wishlist.isEmpty {
          ContentUnavailableView {
            Label(String(localized: "Search", bundle: .module), systemImage: "magnifyingglass")
          } description: {
            Text("Search courses, codes or professors, or browse with filters.", bundle: .module)
          }
        } else {
          // With nothing to search for yet, the lectures saved for this semester come first.
          results(
            for: viewModel.wishlist,
            showsRatings: false,
            wishlistHeader: String(localized: "Wishlist", bundle: .module)
          )
        }
      } else {
        switch viewModel.state {
        case .loading:
          ProgressView()
        case .error(let message):
          ContentUnavailableView {
            Label(String(localized: "Error", bundle: .module), systemImage: "exclamationmark.circle")
          } description: {
            Text(message)
          } actions: {
            Button(String(localized: "Retry", bundle: .module)) {
              viewModel.retry()
            }
          }
        case .loaded:
          if viewModel.courses.isEmpty {
            noResults
          } else {
            results(for: viewModel.courses)

            if viewModel.canLoadMore {
              ProgressView()
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .task(id: viewModel.loadedLectureCount) {
                  await viewModel.loadMore()
                }
            }
          }
        }
      }
    }
    // Soft edges let the results fade under the title and under the filter chips and search field.
    .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
    .contentWidth()
    .safeAreaBar(edge: .bottom) {
      VStack(spacing: 8) {
        CourseFilterBar(
          filter: $viewModel.filter,
          time: $viewModel.time,
          selectedDepartments: viewModel.selectedDepartments,
          onSelectDepartments: onSelectDepartments,
          onChooseTimeOnTimetable: onChooseTimeOnTimetable
        )
        LectureSearchField(text: $viewModel.searchKeyword, isFocused: isSearchFocused)
          .padding(.horizontal)
      }
      .padding(.bottom, isSearchFocused.wrappedValue ? 8 : 0)
      .contentWidth()
    }
    .scrollDismissesKeyboard(.immediately)
    .onAppear {
      viewModel.bind(selectedSemester: selectedSemester)
    }
    // The semester can change while the list stays on screen, such as after a refresh.
    .onChange(of: selectedSemester) {
      viewModel.bind(selectedSemester: selectedSemester)
    }
    .task {
      await viewModel.fetchDepartments()
    }
    .task(id: selectedSemester) {
      await viewModel.fetchWishlist(semester: selectedSemester)
    }
    .wishlistErrorAlert(viewModel)
  }

  private func results(
    for courses: [CourseLecture],
    showsRatings: Bool = true,
    wishlistHeader: String? = nil
  ) -> some View {
    LectureSearchResults(
      courses: courses,
      timetable: timetable,
      onOpenLecture: onOpenLecture,
      onOpenCourse: onOpenCourse,
      onAddLecture: onAddLecture,
      wishlistedLectureIDs: viewModel.wishlistedLectureIDs,
      onToggleWishlist: { lecture in Task { await viewModel.toggleWishlist(lecture) } },
      showsRatings: showsRatings,
      wishlistHeader: wishlistHeader
    )
  }

  @ViewBuilder
  private var noResults: some View {
    if viewModel.filter.isEmpty && viewModel.time.isEmpty {
      ContentUnavailableView.search(text: viewModel.searchKeyword)
    } else {
      ContentUnavailableView {
        Label(String(localized: "No Results", bundle: .module), systemImage: "magnifyingglass")
      } description: {
        Text("Try a different keyword or remove some filters.", bundle: .module)
      }
    }
  }
}

extension View {
  /// Says why a wishlist change was undone. Lectures pushed over the results need it too, since an
  /// alert on a screen they cover does not appear.
  func wishlistErrorAlert(_ viewModel: LectureSearchViewModel) -> some View {
    alert(
      String(localized: "Couldn't Update Wishlist", bundle: .module),
      isPresented: Binding(get: { viewModel.wishlistError != nil }, set: { if !$0 { viewModel.wishlistError = nil } }),
      actions: { Button(String(localized: "Okay", bundle: .module), role: .close) { } },
      message: { Text(viewModel.wishlistError ?? "") }
    )
  }
}

/// Builds the screens pushed from lecture search, the same way in each presentation.
struct LectureSearchDestination: View {
  let route: LectureSearchRoute
  let viewModel: LectureSearchViewModel
  let timetable: Timetable?
  let onAdd: (Lecture) -> Void

  var body: some View {
    switch route {
    case .lecture(let lecture):
      LectureDetailView(
        lecture: lecture,
        onAdd: { onAdd(lecture) },
        conflicts: timetable?.conflicts(with: lecture) ?? [],
        isAdded: timetable?.contains(lecture) ?? false,
        isWishlisted: viewModel.isWishlisted(lecture),
        onToggleWishlist: { Task { await viewModel.toggleWishlist(lecture) } },
        lectureClass: lecture.classes.first
      )
    case .course(let id, let name):
      CourseView(courseID: id, name: name)
    }
  }
}
