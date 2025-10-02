//
//  LectureDetailView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/06/2025.
//

import SwiftUI

struct LectureDetailView: View {
  let lecture: Lecture
  let onAdd: (() -> Void)?
  let isOverlapping: Bool

  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = LectureDetailViewModel()

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        // Lecture Summary
        LectureSummary(lecture: lecture)

        // Lecture Information
        lectureInformation

        // Lecture Reviews
        lectureReviews
      }
      .padding([.horizontal, .bottom])
    }
    .task {
      await viewModel.fetchReviews(lectureID: lecture.id)
    }
    .navigationTitle(lecture.title.localized())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if onAdd != nil {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add", systemImage: "plus", role: .confirm) {
            dismiss()
            onAdd?()
          }
          .disabled(isOverlapping)
        }
      }
    }
  }

  var lectureReviews: some View {
    VStack {
      HStack {
        Text("Reviews")
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }

      HStack {
        LectureSummaryRow(title: "Grade", description: lecture.gradeLetter)
        Spacer()
        LectureSummaryRow(title: "Load", description: lecture.loadLetter)
        Spacer()
        LectureSummaryRow(title: "Speech", description: lecture.speechLetter)
        Spacer()

        Button(action: { }, label: {
          Label("Write a Review", systemImage: "square.and.pencil")
            .padding(8)
        })
        .font(.callout)
        .buttonStyle(.glassProminent)
        .tint(Color.secondarySystemBackground)
        .foregroundStyle(.primary)
      }
      .padding(.vertical, 4)

      Spacer()
        .frame(height: 16)

      LazyVStack(spacing: 16) {
        if viewModel.state == .loading {
          ForEach(LectureReview.mockList.prefix(2)) { review in
            LectureReviewCell(review: .constant(review))
              .redacted(reason: .placeholder)
          }
        } else {
          ForEach($viewModel.reviews) { $review in
            LectureReviewCell(review: $review)
          }
        }
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

      LectureDetailRow(title: "Code", description: lecture.code)
      LectureDetailRow(title: "Type", description: lecture.typeDetail.localized())
      LectureDetailRow(title: "Department", description: lecture.department.name.localized())
      LectureDetailRow(
        title: "Professor",
        description: lecture.professors.isEmpty ? "Unknown" : lecture.professors.map { $0.name.localized() }.joined(separator: "\n")
      )
      LectureDetailRow(
        title: "Classroom",
        description: lecture.classTimes.first?.classroomNameShort.localized() ?? "Unknown"
      )
      LectureDetailRow(title: "Capacity", description: String(lecture.capacity))
      LectureDetailRow(
        title: "Exams",
        description: lecture.examTimes.isEmpty ? "Unknown" : lecture.examTimes
          .map { $0.description.localized() }
          .joined(separator: "\n")
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
}

#Preview {
  LectureDetailView(lecture: Lecture.mock, onAdd: nil, isOverlapping: false)
}
