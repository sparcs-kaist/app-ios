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

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        if viewModel.searchKeyword.isEmpty {
          ContentUnavailableView(
            "Search",
            systemImage: "magnifyingglass",
            description: Text("Search courses, codes or professors.", bundle: .module)
          )
        } else if viewModel.courses.isEmpty && viewModel.state != .loading {
          ContentUnavailableView.search(text: viewModel.searchKeyword)
        } else if viewModel.state == .loading {
          ProgressView()
        } else {
          LectureSearchResults(
            courses: viewModel.courses,
            candidateLecture: $candidateLecture,
            detent: $detent,
            onAdd: onAdd
          )
        }
      }
      .contentWidth()
      .navigationTitle(String(localized: "Add to \"\(timetableDisplayName)\"", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      #if os(macOS)
      // This sheet had no toolbar item at all, so Escape was the only way out on the
      // Mac — there is no swipe to fall back on there. iOS keeps its drag indicator.
      .toolbar {
        ToolbarItem(placement: .sheetCancellation) {
          Button(String(localized: "Cancel", bundle: .module), systemImage: "xmark", role: .close) {
            dismiss()
          }
        }
      }
      #endif
      .searchable(text: $viewModel.searchKeyword)
      .scrollDismissesKeyboard(.immediately)
      .onAppear {
        viewModel.bind(selectedSemester: selectedSemester)
      }
    }
    .analyticsScreen(name: "Lecture Search", class: String(describing: Self.self))
  }

}

//#Preview {
//  LectureSearchView(detent: .constant(.medium))
//    .environment(TimetableViewModel())
//}
//
