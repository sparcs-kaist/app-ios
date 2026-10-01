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
  private let courseID: Int
  private let name: String
  /// Shown until the full course loads, when the caller already has it.
  private let summary: CourseSummary?

  public init(course: CourseSummary, viewModel: CourseViewModel = .init()) {
    self.viewModel = viewModel
    self.courseID = course.id
    self.name = course.name
    self.summary = course
  }

  /// Opens a course known only by ID, such as a lecture search result.
  public init(courseID: Int, name: String, viewModel: CourseViewModel = .init()) {
    self.viewModel = viewModel
    self.courseID = courseID
    self.name = name
    self.summary = nil
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
            code: viewModel.course?.code ?? summary?.code ?? "",
            typeName: (viewModel.course?.type ?? summary?.type)?.displayName.localized() ?? "",
            departmentName: viewModel.course?.department.name ?? summary?.department.name ?? "",
            summary: viewModel.course?.summary ?? summary?.summary ?? ""
          )
          .redacted(reason: viewModel.course == nil && summary == nil ? .placeholder : [])

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
    .navigationTitle(name)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.setup(courseID: courseID)
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
