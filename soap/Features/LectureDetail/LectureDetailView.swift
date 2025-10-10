//
//  LectureDetailView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/06/2025.
//

import SwiftUI
import Factory
import BuddyDomain

struct LectureDetailView: View {
  let lecture: Lecture
  let onAdd: (() -> Void)?
  let isOverlapping: Bool

  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol

  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = LectureDetailViewModel()
  @State private var showReviewComposeView: Bool = false
  @State private var canWriteReview: Bool = false

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
      let otl = await userUseCase.otlUser
      canWriteReview = otl?.reviewWritableLectures.contains { $0.id == lecture.id } ?? false
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
    .sheet(isPresented: $showReviewComposeView) {
      ReviewComposeView(lecture: lecture, onWrite: { review in
        viewModel.reviews.insert(review, at: 0)
      })
      .presentationDragIndicator(.visible)
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
        LectureSummaryRow(title: String(localized: "Grade"), description: lecture.gradeLetter)
        Spacer()
        LectureSummaryRow(title: String(localized: "Load"), description: lecture.loadLetter)
        Spacer()
        LectureSummaryRow(title: String(localized: "Speech"), description: lecture.speechLetter)
        Spacer()

        Button(action: {
          showReviewComposeView = true
        }, label: {
          Label("Write a Review", systemImage: "square.and.pencil")
            .foregroundStyle(canWriteReview ? .primary : .secondary)
            .padding(8)
        })
        .font(.callout)
        .buttonStyle(.glassProminent)
        .tint(Color.secondarySystemBackground)
        .foregroundStyle(.primary)
        .disabled(!canWriteReview)
      }
      .padding(.vertical, 4)

      Spacer()
        .frame(height: 16)

      LazyVStack(spacing: 16) {
        switch viewModel.state {
        case .loading:
          ForEach(LectureReview.mockList.prefix(2)) { review in
            LectureReviewCell(review: .constant(review))
              .redacted(reason: .placeholder)
          }
        case .loaded:
          if viewModel.reviews.isEmpty {
            // loaded but empty
            ContentUnavailableView("No Reviews", systemImage: "text.book.closed", description: Text("There are no reviews for this lecture yet."))
          } else {
            ForEach($viewModel.reviews) { $review in
              LectureReviewCell(review: $review)
            }
          }
        case .error(let message):
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
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

      LectureDetailRow(title: String(localized: "Code"), description: lecture.code)
      LectureDetailRow(title: String(localized: "Type"), description: lecture.typeDetail.localized())
      LectureDetailRow(title: String(localized: "Department"), description: lecture.department.name.localized())
      LectureDetailRow(
        title: String(localized: "Professor"),
        description: lecture.professors.isEmpty ? String(localized: "Unknown") : lecture.professors.map { $0.name.localized() }.joined(separator: "\n")
      )
      LectureDetailRow(
        title: String(localized: "Classroom"),
        description: lecture.classTimes.first?.classroomNameShort.localized() ?? String(localized: "Unknown")
      )
      LectureDetailRow(title: String(localized: "Capacity"), description: String(lecture.capacity))
      LectureDetailRow(
        title: String(localized: "Exams"),
        description: lecture.examTimes.isEmpty ? String(localized: "Unknown") : lecture.examTimes
          .map { $0.description.localized() }
          .joined(separator: "\n")
      )

      // Lecture Action Buttons
//      Button(action: { }, label: {
//        HStack {
//          Text("View Dictionary")
//          Spacer()
//          Image(systemName: "text.book.closed")
//        }
//      })
//      .font(.callout)
//      .padding(.vertical, 4)
//      Divider()
//
//      Button(action: { }, label: {
//        HStack {
//          Text("View Syllabus")
//          Spacer()
//          Image(systemName: "append.page")
//        }
//      })
//      .font(.callout)
//      .padding(.vertical, 4)
//      Divider()
    }
  }
}

#Preview {
  LectureDetailView(lecture: Lecture.mock, onAdd: nil, isOverlapping: false)
}
