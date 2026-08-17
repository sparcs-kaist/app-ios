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
  /// Whether this is the sheet the timetable presents, rather than a push inside the
  /// lecture search. Only the sheet needs a close button, and only on macOS — pushed
  /// instances already have a back button.
  let isPresentedAsSheet: Bool

  init(
    lecture: Lecture,
    onAdd: (() -> Void)?,
    isOverlapping: Bool,
    lectureClass: LectureClass? = nil,
    isPresentedAsSheet: Bool = false
  ) {
    self.lecture = lecture
    self.onAdd = onAdd
    self.isOverlapping = isOverlapping
    self.lectureClass = lectureClass
    self.isPresentedAsSheet = isPresentedAsSheet
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
      #if os(macOS)
      // As a sheet this screen has no toolbar item unless `onAdd` is set, and the
      // timetable passes nil — which left Escape as the only way out on the Mac.
      if isPresentedAsSheet {
        ToolbarItem(placement: .sheetCancellation) {
          Button(String(localized: "Cancel", bundle: .module), systemImage: "xmark", role: .close) {
            dismiss()
          }
        }
      }
      #endif

      if onAdd != nil {
        ToolbarItem(placement: .sheetConfirmation) {
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
