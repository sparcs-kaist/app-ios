//
//  CourseView.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import Foundation
import SwiftUI
import BuddyDomain
import FirebaseAnalytics

public struct CourseView: View {
  @State private var viewModel: CourseViewModel
  @State private var course: CourseSummary

  public init(course: CourseSummary, viewModel: CourseViewModel = .init()) {
    self.viewModel = viewModel
    self.course = course
  }
  
  public var body: some View {
    ScrollView {
      Group {
        switch viewModel.state {
        case .loading, .loaded:
          courseSummary
          courseReview
        case .error(let message):
          ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
      .padding(.horizontal)
    }
    .navigationTitle(course.name)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.setup(courseID: course.id)
    }
    .analyticsScreen(name: "Course", class: String(describing: Self.self))
  }
  
  private var courseSummary: some View {
    Group {
      VStack(spacing: 20) {
        HStack {
          lectureSummaryRowWrapper(
            title: "Hours",
            description: String(viewModel.course?.classDuration ?? 0)
          )
          lectureSummaryRowWrapper(title: "Lab", description: String(viewModel.course?.expDuration ?? 0))
          if viewModel.course?.credit == 0 {
            lectureSummaryRowWrapper(title: "AU", description: String(viewModel.course?.creditAU ?? 0))
          } else {
            lectureSummaryRowWrapper(title: "Credit", description: String(viewModel.course?.credit ?? 0))
          }
        }

        VStack(alignment: .leading) {
          HStack {
            Text("Information", bundle: .module)
              .font(.title3)
              .fontWeight(.bold)
            Spacer()
          }

          LectureDetailRow(title: "Code", description: course.code)
          LectureDetailRow(title: "Type", description: course.type.displayName.localized())
          LectureDetailRow(title: "Department", description: course.department.name)

          if course.summary != "" {
            Text("Summary", bundle: .module)
              .foregroundStyle(.secondary)
              .font(.callout)
              .padding(.vertical, 4)

            Text(course.summary)
              .font(.footnote)
              .multilineTextAlignment(.leading)
          }
        }
      }
    }
    .padding(.bottom)
  }
  
  private var courseReview: some View {
    VStack {
      HStack {
        Text("Reviews", bundle: .module)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()

        lectureSummaryRowWrapper(
          title: "Grade",
          description: viewModel.reviewPage?
            .getGradeLetter(
              for: (viewModel.course?.credit ?? 0) + (viewModel.course?.creditAU ?? 0)
            ) ?? "?"
        )
        lectureSummaryRowWrapper(
          title: "Load", 
          description: viewModel.reviewPage?
            .getLoadLetter(
              for: (viewModel.course?.credit ?? 0) + (viewModel.course?.creditAU ?? 0)
            ) ?? "?"
        )
        lectureSummaryRowWrapper(
          title: "Speech",
          description: viewModel.reviewPage?
            .getSpeechLetter(
              for: (viewModel.course?.credit ?? 0) + (viewModel.course?.creditAU ?? 0)
            ) ?? "?"
        )
      }
      
      Spacer()
        .frame(height: 16)

      LazyVStack(spacing: 16) {
        if viewModel.state == .loaded {
          ForEach($viewModel.reviews) { $review in
            LectureReviewCell(review: $review)
          }
        } else {
          ForEach(LectureReview.mockList.prefix(3)) { review in
            LectureReviewCell(review: .constant(review))
              .redacted(reason: .placeholder)
          }
        }
      }
    }
  }
  
  func lectureSummaryRowWrapper(title: String, description: String) -> some View {
    LectureSummaryRow(title: title, description: description)
      .frame(width: 75)
  }
}

//#Preview {
//  CourseView(course: .mock)
//}
