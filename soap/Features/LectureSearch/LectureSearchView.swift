//
//  LectureSearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI

struct LectureSearchView: View {
  @Binding var detent: PresentationDetent

  @Environment(TimetableViewModel.self) private var timetableViewModel: TimetableViewModel
  @State private var viewModel = LectureSearchViewModel()

  var body: some View {
    NavigationStack {
      List {
        if viewModel.searchKeyword.isEmpty {
          ContentUnavailableView(
            "Search",
            systemImage: "magnifyingglass",
            description: Text("Search courses, codes or professors.")
          )
        } else if viewModel.lectures.isEmpty && viewModel.state != .loading {
          ContentUnavailableView.search(text: viewModel.searchKeyword)
        } else if viewModel.state == .loading {
          ProgressView()
        } else {
          searchResultView
        }
      }
      .navigationTitle("Add to \"\(timetableViewModel.selectedTimetableDisplayName)\"")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $viewModel.searchKeyword)
      .scrollDismissesKeyboard(.immediately)
      .onAppear {
        viewModel.bind()
      }
    }
  }

  @ViewBuilder
  var searchResultView: some View {
    let groupedByCourse = Dictionary(grouping: viewModel.lectures, by: { $0.course })
    // Preserve the order of first appearance from the original list
    let orderedCourses: [Int] = {
      var seen = Set<Int>()
      var result: [Int] = []
      for lecture in viewModel.lectures {
        if seen.insert(lecture.course).inserted {
          result.append(lecture.course)
        }
      }
      return result
    }()

    ForEach(orderedCourses, id: \.self) { course in
      Section {
        if let firstItem = groupedByCourse[course]?.first {
          HStack {
            Text(firstItem.title.localized())
              .lineLimit(2)
              .multilineTextAlignment(.leading)
              .font(.callout)
              .fontWeight(.semibold)

            Spacer()

            VStack(alignment: .trailing) {
              Text(firstItem.code)
              Text(firstItem.typeDetail.localized())
            }
            .foregroundStyle(.secondary)
            .font(.footnote)
          }
        }
        ForEach(groupedByCourse[course] ?? []) { lecture in
          NavigationLink(destination: {
            LectureDetailView(
              lecture: lecture,
              onAdd: {
                Task {
                  do {
                    try await timetableViewModel.addLecture(lecture: lecture)
                  } catch {
                    timetableViewModel.handleException(error: error, type: .addLecture)
                  }
                }
              },
              isOverlapping: timetableViewModel.isCandidateOverlapping,
              classTime: lecture.classTimes.first
            )
            .onAppear {
              timetableViewModel.candidateLecture = lecture
              detent = .height(130)
            }
            .onDisappear {
              timetableViewModel.candidateLecture = nil
              detent = .large
            }
          }, label: {
            HStack {
              Text(lecture.section ?? "A")
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)

              Text(lecture.professors.first?.name.localized() ?? String(localized: "Unknown"))

              Spacer()
            }
            .font(.callout)
          })
        }
      }
    }
  }
}

#Preview {
  LectureSearchView(detent: .constant(.medium))
    .environment(TimetableViewModel())
}

