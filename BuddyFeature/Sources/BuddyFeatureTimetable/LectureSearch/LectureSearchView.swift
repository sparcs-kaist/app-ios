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
  /// The timetable being added to, for spotting lectures that are already in it or overlap it.
  let timetable: Timetable?
  let selectedSemester: Semester
  @Binding var candidateLecture: Lecture?
  let onAdd: (Lecture) -> Void

  @State private var viewModel = LectureSearchViewModel()
  @State private var showDepartmentPicker: Bool = false
  @State private var path: [LectureSearchRoute] = []
  /// Whether the sheet offers its short preview height; see `detents`.
  @State private var offersPreviewHeight = false
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
              LectureSearchResults(courses: viewModel.courses, timetable: timetable, onOpenLecture: openLecture)

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
          setDetent(.large)
        }
      }
      .navigationDestination(for: LectureSearchRoute.self) { route in
        switch route {
        case .lecture(let lecture):
          LectureDetailView(
            lecture: lecture,
            onAdd: { onAdd(lecture) },
            conflicts: timetable?.conflicts(with: lecture) ?? [],
            isAdded: timetable?.contains(lecture) ?? false,
            lectureClass: lecture.classes.first
          )
        case .course(let id, let name):
          CourseView(courseID: id, name: name)
        }
      }
      .onChange(of: path) { oldPath, newPath in
        // Popping the previewed lecture ends the preview as the results come back into view.
        // Views pushed on top of the lecture, such as its course page, leave it alone.
        if oldPath.first?.lecture != nil && newPath.first?.lecture == nil {
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
          setDetent(.large)
        }
      }
      .onAppear {
        viewModel.bind(selectedSemester: selectedSemester)
      }
      .task {
        await viewModel.fetchDepartments()
      }
    }
    // While a lecture is open the sheet is often at its smallest height, where a stray
    // downward swipe would dismiss the whole search. Leaving goes through the back button.
    .interactiveDismissDisabled(path.first?.lecture != nil)
    // Only a lecture opened from the results is shown short; every other screen pushed in the
    // search, such as the course page however it is reached, asks for full height.
    .environment(\.expandSheet, { setDetent(.large) })
    .presentationDetents(detents, selection: $detent)
    .analyticsScreen(name: "Lecture Search", class: String(describing: Self.self))
  }

  /// Tall enough for the lecture's title and Add button, short enough to show the timetable.
  private static let previewHeight = PresentationDetent.height(130)

  /// The short height only exists while a lecture is previewed, so the results cannot be
  /// dragged down to a height too small to use.
  private var detents: Set<PresentationDetent> {
    offersPreviewHeight ? [Self.previewHeight, .medium, .large] : [.medium, .large]
  }

  /// Opens a lecture from the results: previews it on the timetable and shrinks the sheet so
  /// its time slot is visible, then pushes its details.
  private func openLecture(_ lecture: Lecture) {
    // An open keyboard holds the sheet up, so the shrink would not take effect.
    isSearchFocused = false
    candidateLecture = lecture
    offersPreviewHeight = true
    setDetent(Self.previewHeight)
    path.append(.lecture(lecture))
  }

  /// Back on the results, the sheet opens to full height so there is room to browse them.
  private func endPreview() {
    candidateLecture = nil
    setDetent(.large)
    offersPreviewHeight = false
  }

  /// Animates the sheet to a new height rather than letting it jump.
  private func setDetent(_ newDetent: PresentationDetent) {
    withAnimation(.smooth) {
      detent = newDetent
    }
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
