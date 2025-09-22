//
//  LectureSearchView.swift
//  soap
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI

struct LectureSearchView: View {
  @Environment(TimetableViewModel.self) private var timetableViewModel: TimetableViewModel
  @State private var searchText: String = ""
  @State private var isFiltered: Bool = false

  var body: some View {
    let groupedByCourse = Dictionary(grouping: Lecture.mockList, by: { $0.course })
    // Preserve the order of first appearance from the original list
    let orderedCourses: [Int] = {
      var seen = Set<Int>()
      var result: [Int] = []
      for lecture in Lecture.mockList {
        if seen.insert(lecture.course).inserted {
          result.append(lecture.course)
        }
      }
      return result
    }()

    NavigationStack {
      List {
        ForEach(orderedCourses, id: \.self) { course in
          Section {
            if let firstItem = groupedByCourse[course]?.first {
              HStack {
                Text(firstItem.title.localized())
                  .font(.callout)

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
                LectureDetailView(lecture: lecture, onAdd: {

                })
                  .onAppear {
                    timetableViewModel.candidateLecture = lecture
                  }
                  .onDisappear {
                    timetableViewModel.candidateLecture = nil
                  }
              }, label: {
                HStack {
                  Text(lecture.section ?? "A")
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)

                  Text(lecture.professors.first?.name.localized() ?? "Unknown")

                  Spacer()
                }
                .font(.callout)
              })
            }
          }
        }
      }
      .navigationTitle("Add to \"My Table\"")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, prompt: Text("Search courses, codes or professors"))
    }
  }
}

#Preview {
  LectureSearchView()
}

