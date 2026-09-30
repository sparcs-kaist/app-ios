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

struct LectureSearchView: View {
  @Binding var detent: PresentationDetent
  let timetableDisplayName: String
  let selectedSemester: Semester
  @Binding var candidateLecture: Lecture?
  let onAdd: (Lecture) -> Void

  @State private var viewModel = LectureSearchViewModel()
  @State private var showDepartmentPicker: Bool = false
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    NavigationStack {
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
              LectureSearchResults(
                courses: viewModel.courses,
                candidateLecture: $candidateLecture,
                detent: $detent,
                onAdd: onAdd
              )

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
      .contentWidth()
      .safeAreaBar(edge: .bottom) {
        VStack(spacing: 8) {
          LectureSearchFilterBar(
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
      .navigationDestination(isPresented: $showDepartmentPicker) {
        LectureDepartmentPicker(
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
