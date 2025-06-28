//
//  LectureDetailView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/06/2025.
//

import SwiftUI

struct LectureDetailView: View {
  let lecture: Lecture

  var body: some View {
    NavigationView {
      ScrollView {
        LazyVStack {
          HStack {

          }

          lectureDetailRow(title: "Code", description: lecture.code)
          lectureDetailRow(title: "Type", description: lecture.typeDetail.localized())
          lectureDetailRow(title: "Department", description: lecture.department.localized())
          lectureDetailRow(
            title: "Professor",
            description: lecture.professors.isEmpty ? "Unknown" : lecture.professors.map { $0.name.localized() }.joined(separator: "\n")
          )
          lectureDetailRow(
            title: "Classroom",
            description: lecture.classTimes.first?.classroomNameShort.localized() ?? "Unknown"
          )
          lectureDetailRow(title: "Capacity", description: String(lecture.capacity))
          lectureDetailRow(
            title: "Exams",
            description: lecture.examTimes.isEmpty ? "Unknown" : lecture.examTimes.map { $0.str.localized() }.joined(separator: "\n")
          )

          Text("hello")
        }
        .padding()
      }
      .navigationTitle(lecture.title.localized())
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu("More", systemImage: "ellipsis") {
            Button("View Dictionary", systemImage: "text.book.closed") { }
            Button("View Syllabus", systemImage: "append.page") { }
          }
        }
      }
    }
  }

  @ViewBuilder
  func lectureDetailRow(title: String, description: String) -> some View {
    HStack {
      Text(title)
        .foregroundStyle(.secondary)
        .font(.callout)
      Spacer()
      Text(description)
        .font(.callout)
        .multilineTextAlignment(.trailing)
    }
    .padding(.vertical, 4)
    Divider()
  }
}

#Preview {
  LectureDetailView(lecture: Lecture.mock)
}
