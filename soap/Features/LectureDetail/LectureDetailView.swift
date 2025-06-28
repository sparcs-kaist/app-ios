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
        LazyVStack(spacing: 20) {
          // Lecture Summary
          lectureSummary

          // Lecture Information
          lectureInformation

          // Lecture Reviews
          lectureReviews
        }
        .padding([.horizontal, .bottom])
      }
      .navigationTitle(lecture.title.localized())
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  var lectureReviews: some View {
    LazyVStack {
      HStack {
        Text("Reviews")
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }
    }
  }

  var lectureInformation: some View {
    VStack {
      HStack {
        Text("Information")
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
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

      // Lecture Action Buttons
      Button(action: { }, label: {
        HStack {
          Text("View Dictionary")
          Spacer()
          Image(systemName: "text.book.closed")
        }
      })
      .font(.callout)
      .padding(.vertical, 4)
      Divider()

      Button(action: { }, label: {
        HStack {
          Text("View Syllabus")
          Spacer()
          Image(systemName: "append.page")
        }
      })
      .font(.callout)
      .padding(.vertical, 4)
      Divider()
    }
  }

  var lectureSummary: some View {
    HStack {
      lectureSummaryRow(title: "Language", description: lecture.isEnglish ? "EN" : "한")
      Spacer()
      lectureSummaryRow(
        title: "Credits",
        description: String(lecture.credit + lecture.creditAu)
      )
      Spacer()
      lectureSummaryRow(
        title: "Competition",
        description: (lecture.capacity == 0 || lecture.numberOfPeople == 0)
        ?
        "0.0:1"
        :
          String(
            format: "%.1f",
            Float(lecture.numberOfPeople) / Float(lecture.capacity)
          ) + ":1"
      )
      Spacer()
      lectureSummaryRow(title: "Grade", description: "A+")
      Spacer()
      lectureSummaryRow(title: "Load", description: "A+")
      Spacer()
      lectureSummaryRow(title: "Speech", description: "A+")
    }
  }

  func lectureSummaryRow(title: String, description: String) -> some View {
    VStack(spacing: 8) {
      Text(title)
        .foregroundStyle(.tertiary)
        .font(.caption2)
        .fontWeight(.medium)
        .textCase(.uppercase)

      Text(description)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
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
