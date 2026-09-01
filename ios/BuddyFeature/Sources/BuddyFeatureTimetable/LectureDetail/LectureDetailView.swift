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
        LectureInformationSection(lecture: lecture, lectureClass: lectureClass)

        // Lecture Reviews
        LectureReviewsSection(
          gradeLetter: lecture.gradeLetter,
          loadLetter: lecture.loadLetter,
          speechLetter: lecture.speechLetter,
          state: viewModel.state,
          reviews: $viewModel.reviews,
          canWriteReview: canWriteReview,
          onWriteReview: { showReviewComposeView = true }
        )
      }
      .padding([.horizontal, .bottom])
      .contentWidth()
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

}

//#Preview {
//  LectureDetailView(lecture: Lecture.mock, onAdd: nil, isOverlapping: false)
//}
