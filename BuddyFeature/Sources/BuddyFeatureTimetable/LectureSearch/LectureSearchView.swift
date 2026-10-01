//
//  LectureSearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import Foundation
import SwiftUI
import FirebaseAnalytics
import BuddyDomain
import BuddyFeatureShared

struct LectureSearchView: View {
  @Binding var detent: PresentationDetent
  let timetableDisplayName: String
  let selectedSemester: Semester
  @Binding var candidateLecture: Lecture?
  let onAdd: (Lecture) -> Void

  @State private var viewModel = LectureSearchViewModel()
  @State private var showDepartmentPicker: Bool = false
  @State private var path: [LectureSearchRoute] = []
  /// The sheet height to return to once the user leaves a lecture they opened from the results.
  @State private var detentBeforePreview: PresentationDetent?
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    NavigationStack(path: $path) {
      List {
        if !viewModel.hasCriteria {
          ContentUnavailableView {
            Label(String(localized: "Search", bundle: .module), systemImage: "magnifyingglass")
          } description: {
            Text("Search courses, codes or professors, or browse with filters.", bundle: .module)
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
              LectureSearchResults(courses: viewModel.courses)

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
      // A soft edge lets the results fade under the filter chips and search field.
      .scrollEdgeEffectStyle(.soft, for: .bottom)
      .contentWidth()
      .safeAreaBar(edge: .bottom) {
        VStack(spacing: 8) {
          CourseFilterBar(
            filter: $viewModel.filter,
            selectedDepartments: viewModel.selectedDepartments,
            onSelectDepartments: { showDepartmentPicker = true }
          )
          LectureSearchField(text: $viewModel.searchKeyword, isFocused: $isSearchFocused)
            .padding(.horizontal)
        }
        .padding(.bottom, isSearchFocused ? 8 : 0)
        .contentWidth()
      }
      .navigationTitle(String(localized: "Add to \"\(timetableDisplayName)\"", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .scrollDismissesKeyboard(.immediately)
      .onChange(of: isSearchFocused) {
        // Typing needs the room: at the medium height the keyboard would cover the results.
        if isSearchFocused {
          detent = .large
        }
      }
      .navigationDestination(for: LectureSearchRoute.self) { route in
        switch route {
        case .lecture(let lecture):
          LectureDetailView(
            lecture: lecture,
            onAdd: { onAdd(lecture) },
            isOverlapping: false,
            lectureClass: lecture.classes.first
          )
        case .course(let id, let name):
          CourseView(courseID: id, name: name)
        }
      }
      .onChange(of: path) { oldPath, newPath in
        // Only a lecture opened straight from the results is previewed. Views pushed on top of
        // it, such as its course page, leave the preview and the sheet height alone.
        let oldLecture = oldPath.first?.lecture
        let newLecture = newPath.first?.lecture
        guard oldLecture != newLecture else { return }
        if let newLecture {
          startPreview(newLecture)
        } else {
          endPreview()
        }
      }
      .navigationDestination(isPresented: $showDepartmentPicker) {
        DepartmentPicker(
          departments: viewModel.departments,
          interestedDepartmentIDs: viewModel.interestedDepartmentIDs,
          state: viewModel.departmentState,
          selection: $viewModel.filter.departmentIDs,
          onRetry: { await viewModel.fetchDepartments() }
        )
        .onAppear {
          detent = .large
        }
      }
      .onAppear {
        viewModel.bind(selectedSemester: selectedSemester)
      }
      .task {
        await viewModel.fetchDepartments()
      }
    }
    .analyticsScreen(name: "Lecture Search", class: String(describing: Self.self))
  }

  /// Shows the lecture on the timetable and shrinks the sheet so its time slot is visible.
  private func startPreview(_ lecture: Lecture) {
    // An open keyboard holds the sheet up, so the shrink would not take effect.
    isSearchFocused = false
    candidateLecture = lecture
    if detentBeforePreview == nil {
      detentBeforePreview = detent
    }
    detent = .height(130)
  }

  private func endPreview() {
    candidateLecture = nil
    detent = detentBeforePreview ?? .large
    detentBeforePreview = nil
  }

  @ViewBuilder
  private var noResults: some View {
    if viewModel.filter.isEmpty {
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

//#Preview {
//  LectureSearchView(detent: .constant(.medium))
//    .environment(TimetableViewModel())
//}
//
