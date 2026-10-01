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
  /// Lectures and activities in the timetable whose times overlap this lecture.
  let conflicts: [String]
  /// Whether the timetable already holds this lecture.
  let isAdded: Bool
  let lectureClass: LectureClass?

  init(
    lecture: Lecture,
    onAdd: (() -> Void)?,
    conflicts: [String] = [],
    isAdded: Bool = false,
    lectureClass: LectureClass? = nil
  ) {
    self.lecture = lecture
    self.onAdd = onAdd
    self.conflicts = conflicts
    self.isAdded = isAdded
    self.lectureClass = lectureClass
  }

  private var isOverlapping: Bool { !conflicts.isEmpty }

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

        if onAdd != nil && !isAdded && isOverlapping {
          conflictWarning
        }

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
          if isAdded {
            Button(String(localized: "Added", bundle: .module), systemImage: "checkmark") { }
              .disabled(true)
          } else {
            // Still tappable when it conflicts, so the alert can say why it cannot be added.
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
    }
    .alert(String(localized: "Cannot Add Lecture", bundle: .module), isPresented: $showCannotAddLectureAlert, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text("This lecture overlaps with \(conflictList) in your timetable.", bundle: .module)
    })
    .sheet(isPresented: $showReviewComposeView) {
      ReviewComposeView(lecture: lecture)
        .presentationDragIndicator(.visible)
    }
    .analyticsScreen(name: "Lecture Detail", class: String(describing: Self.self))
  }

  private var conflictList: String {
    conflicts.formatted(.list(type: .and))
  }

  private var conflictWarning: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Image(systemName: "exclamationmark.triangle.fill")
      Text("Overlaps with \(conflictList)", bundle: .module)
        .multilineTextAlignment(.leading)
      Spacer(minLength: 0)
    }
    .font(.subheadline.weight(.medium))
    .foregroundStyle(.orange)
    .padding(12)
    .background(.orange.opacity(0.12), in: .rect(cornerRadius: 14))
    .accessibilityElement(children: .combine)
  }

}

//#Preview {
//  LectureDetailView(lecture: Lecture.mock, onAdd: nil, isOverlapping: false)
//}
