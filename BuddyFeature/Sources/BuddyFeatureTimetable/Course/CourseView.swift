//
//  CourseView.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI
import BuddyDomain

public struct CourseView: View {
  @State private var viewModel: CourseViewModel
  @State private var course: Course
  
  public init(course: Course, viewModel: CourseViewModel = .init()) {
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
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
      .padding(.horizontal)
    }
    .navigationTitle(course.title.localized())
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.fetchReviews(courseId: course.id)
    }
  }
  
  private var courseSummary: some View {
    Group {
      VStack(spacing: 20) {
        HStack {
          lectureSummaryRowWrapper(title: "Hours", description: String(course.numClasses))
          lectureSummaryRowWrapper(title: "Lab", description: String(course.numLabs))
          if course.credit == 0 {
            lectureSummaryRowWrapper(title: "AU", description: String(course.creditAu))
          } else {
            lectureSummaryRowWrapper(title: "Credit", description: String(course.credit))
          }
        }

        VStack(alignment: .leading) {
          HStack {
            Text("Information")
              .font(.title3)
              .fontWeight(.bold)
            Spacer()
          }

          LectureDetailRow(title: "Code", description: course.code)
          LectureDetailRow(title: "Type", description: course.type.localized())
          LectureDetailRow(title: "Department", description: course.department.name.localized())

          if course.summary != "" {
            Text("Summary")
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
        Text("Reviews")
          .font(.title3)
          .fontWeight(.bold)
        Spacer()

        lectureSummaryRowWrapper(title: "Grade", description: course.gradeLetter)
        lectureSummaryRowWrapper(title: "Load", description: course.loadLetter)
        lectureSummaryRowWrapper(title: "Speech", description: course.speechLetter)
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

#Preview {
  CourseView(course: .mock)
}
