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

  var body: some View {
    NavigationStack {
      List {
        if viewModel.searchKeyword.isEmpty {
          ContentUnavailableView(
            "Search",
            systemImage: "magnifyingglass",
            description: Text(String(localized: "Search courses, codes or professors.", bundle: .module))
          )
        } else if viewModel.courses.isEmpty && viewModel.state != .loading {
          ContentUnavailableView.search(text: viewModel.searchKeyword)
        } else if viewModel.state == .loading {
          ProgressView()
        } else {
          searchResultView
        }
      }
      .navigationTitle(String(localized: "Add to \"\(timetableDisplayName)\"", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $viewModel.searchKeyword)
      .scrollDismissesKeyboard(.immediately)
      .onAppear {
        viewModel.bind(selectedSemester: selectedSemester)
      }
    }
    .analyticsScreen(name: "Lecture Search", class: String(describing: Self.self))
  }

  @ViewBuilder
  var searchResultView: some View {
    ForEach(viewModel.courses) { course in
      Section {
        courseSectionHeader(course: course)
        ForEach(course.lectures) { lecture in
          NavigationLink(destination: {
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
          }, label: {
            courseSectionLecture(lecture: lecture)
          })
        }
      }
    }
  }

  private func courseSectionHeader(course: CourseLecture) -> some View {
    HStack {
      Text(course.name)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .font(.callout)
        .fontWeight(.semibold)

      Spacer()

      VStack(alignment: .trailing) {
        Text(course.code)
        Text(course.type.displayName.localized())
      }
      .foregroundStyle(.secondary)
      .font(.footnote)
    }
  }

  private func courseSectionLecture(lecture: Lecture) -> some View {
    HStack {
      Text(lecture.section)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

      Text(lecture.professors.first?.name ?? String(localized: "Unknown", bundle: .module))

      Spacer()
    }
    .font(.callout)
  }
}

//#Preview {
//  LectureSearchView(detent: .constant(.medium))
//    .environment(TimetableViewModel())
//}
//
