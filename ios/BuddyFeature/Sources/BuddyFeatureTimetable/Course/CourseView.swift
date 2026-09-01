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
          CourseSummarySection(
            classDuration: viewModel.course?.classDuration ?? 0,
            expDuration: viewModel.course?.expDuration ?? 0,
            credit: viewModel.course?.credit ?? 0,
            creditAU: viewModel.course?.creditAU ?? 0,
            code: course.code,
            typeName: course.type.displayName.localized(),
            departmentName: course.department.name,
            summary: course.summary
          )
          CourseReviewSection(
            gradeLetter: gradeLetter,
            loadLetter: loadLetter,
            speechLetter: speechLetter,
            isLoaded: viewModel.state == .loaded,
            reviews: $viewModel.reviews
          )
        case .error(let message):
          ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
      .padding(.horizontal)
      .contentWidth()
    }
    .navigationTitle(course.name)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.setup(courseID: course.id)
    }
    .analyticsScreen(name: "Course", class: String(describing: Self.self))
  }
  
  private var totalCredit: Int {
    (viewModel.course?.credit ?? 0) + (viewModel.course?.creditAU ?? 0)
  }

  private var gradeLetter: String {
    viewModel.reviewPage?.getGradeLetter(for: totalCredit) ?? "?"
  }

  private var loadLetter: String {
    viewModel.reviewPage?.getLoadLetter(for: totalCredit) ?? "?"
  }

  private var speechLetter: String {
    viewModel.reviewPage?.getSpeechLetter(for: totalCredit) ?? "?"
  }
}

//#Preview {
//  CourseView(course: .mock)
//}
