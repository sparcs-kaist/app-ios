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
  let onClose: () -> Void

  @State private var viewModel = LectureSearchViewModel()
  @State private var navigationPath: [Lecture] = []
  #if os(macOS)
  @State private var selectedSearchLecture: Lecture?
  #endif

  var body: some View {
    Group {
      #if os(macOS)
      macOSContent
      #else
      iOSContent
      #endif
    }
    .onAppear {
      viewModel.bind(selectedSemester: selectedSemester)
    }
    .onDisappear {
      candidateLecture = nil
    }
    .analyticsScreen(name: "Lecture Search", class: String(describing: Self.self))
  }

  #if !os(macOS)
  private var iOSContent: some View {
    NavigationStack(path: $navigationPath) {
      searchContent
      .navigationTitle(String(localized: "Add to \"\(timetableDisplayName)\"", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $viewModel.searchKeyword)
      .scrollDismissesKeyboard(.immediately)
      .navigationDestination(for: Lecture.self) { lecture in
        LectureDetailView(
          lecture: lecture,
          onAdd: {
            onAdd(lecture)
          },
          isOverlapping: false,
          lectureClass: lecture.classes.first
        )
        .onAppear {
          candidateLecture = lecture
          detent = .height(130)
        }
        .onDisappear {
          candidateLecture = nil
          detent = .large
        }
      }
    }
  }
  #endif

  #if os(macOS)
  @ViewBuilder
  private var macOSContent: some View {
    if let selectedSearchLecture {
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Button {
            returnToSearch()
          } label: {
            Label(String(localized: "Back", bundle: .module), systemImage: "chevron.left")
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          .keyboardShortcut(.cancelAction)
          .help(String(localized: "Back", bundle: .module))

          Text(selectedSearchLecture.name)
            .font(.headline)
            .lineLimit(1)

          Spacer()

          Button(String(localized: "Add", bundle: .module), systemImage: "plus", role: .confirm) {
            onAdd(selectedSearchLecture)
            returnToSearch()
          }
        }
        .padding()

        Divider()

        LectureDetailView(
          lecture: selectedSearchLecture,
          onAdd: nil,
          isOverlapping: false,
          lectureClass: selectedSearchLecture.classes.first,
          showsNavigationChrome: false
        )
      }
    } else {
      searchContent
    }
  }
  #endif

  @ViewBuilder
  private var searchContent: some View {
    #if os(macOS)
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Add to \"\(timetableDisplayName)\"", bundle: .module)
            .font(.headline)

          Spacer()

          Button(String(localized: "Close", bundle: .module), systemImage: "xmark", action: onClose)
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .keyboardShortcut(.cancelAction)
            .help(String(localized: "Close", bundle: .module))
        }

        TextField(
          String(localized: "Search courses, codes or professors.", bundle: .module),
          text: $viewModel.searchKeyword
        )
        .textFieldStyle(.roundedBorder)
      }
      .padding()

      Divider()
      searchResults
    }
    #else
    searchResults
    #endif
  }

  private var searchResults: some View {
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
          onSelect: selectLecture
        )
      }
    }
    #if !os(macOS)
    .contentWidth()
    #endif
  }

  private func selectLecture(_ lecture: Lecture) {
    #if os(macOS)
    selectedSearchLecture = lecture
    candidateLecture = lecture
    #else
    navigationPath.append(lecture)
    #endif
  }

  #if os(macOS)
  private func returnToSearch() {
    selectedSearchLecture = nil
    candidateLecture = nil
  }
  #endif

}

//#Preview {
//  LectureSearchView(detent: .constant(.medium))
//    .environment(TimetableViewModel())
//}
//
