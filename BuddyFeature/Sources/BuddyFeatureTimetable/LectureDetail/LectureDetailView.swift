//
//  LectureDetailView.swift
//  soap
//
//  Created by Soongyu Kwon on 26/06/2025.
//

import Foundation
import SwiftUI
import Factory
import BuddyDomain
import FirebaseAnalytics

struct LectureDetailView: View {
  let lecture: Lecture
  let onAdd: (() -> Void)?
  let isOverlapping: Bool
  let lectureClass: LectureClass?

  init(lecture: Lecture, onAdd: (() -> Void)?, isOverlapping: Bool, lectureClass: LectureClass? = nil) {
    self.lecture = lecture
    self.onAdd = onAdd
    self.isOverlapping = isOverlapping
    self.lectureClass = lectureClass
  }

  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = LectureDetailViewModel()
  @State private var showReviewComposeView: Bool = false
  @State private var canWriteReview: Bool = false

  @State private var showCannotAddLectureAlert: Bool = false

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
      async let courseFetch = viewModel.fetchCourse(courseID: lecture.courseID)
      async let reviewsFetch = viewModel.fetchReviews(lecture: lecture)

      await courseFetch
      await reviewsFetch

      canWriteReview = viewModel.course?.history.first(where: { $0.myLectureID != nil }) != nil
    }
    .navigationTitle(lecture.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if onAdd != nil {
        ToolbarItem(placement: .topBarTrailing) {
          Button(String(localized: "Add", bundle: .module), systemImage: "plus", role: isOverlapping ? .close : .confirm) {
            if isOverlapping {
              showCannotAddLectureAlert = true
            } else {
              dismiss()
              onAdd?()
            }
          }
        }
      }
    }
    .alert(String(localized: "Cannot Add Lecture", bundle: .module), isPresented: $showCannotAddLectureAlert, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text("This lecture collides with an existing lecture in your timetable.", bundle: .module)
    })
    .sheet(isPresented: $showReviewComposeView) {
      ReviewComposeView(lecture: lecture)
        .presentationDragIndicator(.visible)
    }
    .analyticsScreen(name: "Lecture Detail", class: String(describing: Self.self))
  }

  var lectureReviews: some View {
    VStack {
      HStack {
        Text("Reviews", bundle: .module)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }

      HStack {
        LectureSummaryRow(title: String(localized: "Grade", bundle: .module), description: lecture.gradeLetter)
        Spacer()
        LectureSummaryRow(title: String(localized: "Load", bundle: .module), description: lecture.loadLetter)
        Spacer()
        LectureSummaryRow(title: String(localized: "Speech", bundle: .module), description: lecture.speechLetter)
        Spacer()

        Button(action: {
          showReviewComposeView = true
        }, label: {
          Label(String(localized: "Write a Review", bundle: .module), systemImage: "square.and.pencil")
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
            ContentUnavailableView(String(localized: "No Reviews", bundle: .module), systemImage: "text.book.closed", description: Text("There are no reviews for this lecture yet.", bundle: .module))
          } else {
            ForEach($viewModel.reviews) { $review in
              LectureReviewCell(review: $review)
            }
          }
        case .error(let message):
          ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
    }
  }

  var lectureInformation: some View {
    VStack {
      HStack {
        Text("Information", bundle: .module)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }

      LectureDetailRow(title: String(localized: "Code", bundle: .module), description: lecture.code)
      LectureDetailRow(
        title: String(localized: "Type", bundle: .module),
        description: lecture.type.displayName.localized()
      )
      LectureDetailRow(title: String(localized: "Department", bundle: .module), description: lecture.department.name)
      LectureDetailRow(
        title: String(localized: "Professor", bundle: .module),
        description: lecture.professors.isEmpty ? String(localized: "Unknown", bundle: .module) : lecture.professors.map { $0.name }.joined(separator: "\n")
      )
      if let lectureClass {
        LectureDetailRow(
          title: String(localized: "Classroom", bundle: .module),
          description: "\(lectureClass.buildingCode) \(lectureClass.roomName)"
        )
      }
      LectureDetailRow(title: String(localized: "Capacity", bundle: .module), description: String(lecture.capacity))
      LectureDetailRow(
        title: String(localized: "Exams", bundle: .module),
        description: lecture.exams.isEmpty ? String(localized: "Unknown", bundle: .module) : lecture.exams
          .map { $0.description }
          .joined(separator: "\n")
      )

      // Lecture Action Buttons
//      Button(action: { }, label: {
//        HStack {
//          Text("View Dictionary", bundle: .module)
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
//          Text("View Syllabus", bundle: .module)
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

//#Preview {
//  LectureDetailView(lecture: Lecture.mock, onAdd: nil, isOverlapping: false)
//}
