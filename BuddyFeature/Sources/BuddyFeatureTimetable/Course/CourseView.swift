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
  @Environment(\.expandSheet) private var expandSheet
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
            summary: viewModel.course?.summary ?? summary?.summary ?? "",
            isLoadingDetails: viewModel.course == nil,
            isTaken: isTaken
          )
          .redacted(reason: viewModel.course == nil && summary == nil ? .placeholder : [])

          if let history = viewModel.course?.history {
            if !history.isEmpty {
              CourseHistorySection(
                history: history,
                selectedProfessorID: viewModel.selectedProfessorID,
                onSelectProfessor: viewModel.selectProfessor(id:)
              )
              .padding(.bottom, 28)
            }
          } else {
            CourseHistorySection(
              history: CourseHistorySection.placeholder,
              selectedProfessorID: nil,
              onSelectProfessor: { _ in }
            )
            .redacted(reason: .placeholder)
            .disabled(true)
            .padding(.bottom, 28)
          }

          CourseReviewSection(
            gradeLetter: gradeLetter,
            loadLetter: loadLetter,
            speechLetter: speechLetter,
            professorName: viewModel.selectedProfessor?.name,
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
    .toolbar {
      // Only worth offering when the course has had more than one professor.
      if viewModel.professors.count > 1 {
        ToolbarItem(placement: .bottomBar) {
          professorPicker
        }
        ToolbarSpacer(.flexible, placement: .bottomBar)
      }
    }
    .onAppear {
      // The course page needs room; in the lecture search sheet it may still be short.
      expandSheet?()
    }
    .task {
      await viewModel.setup(courseID: courseID)
    }
    .analyticsScreen(name: "Course", class: String(describing: Self.self))
  }

  /// Picks whose sections to highlight in the history and whose reviews to show.
  private var professorPicker: some View {
    Menu {
      Picker(
        String(localized: "Professor", bundle: .module),
        selection: Binding(get: { viewModel.selectedProfessorID }, set: { viewModel.selectProfessor(id: $0) })
      ) {
        Label(String(localized: "All Professors", bundle: .module), systemImage: "person.2")
          .tag(Int?.none)
        Section {
          ForEach(viewModel.professors) { professor in
            Text(professor.name).tag(Int?.some(professor.id))
          }
        }
      }
    } label: {
      // A plain stack, since toolbars reduce a `Label` to its icon and the name is the point.
      HStack(spacing: 6) {
        Image(systemName: viewModel.selectedProfessor == nil ? "person.2" : "person.crop.circle.fill")
        Text(viewModel.selectedProfessor?.name ?? String(localized: "All Professors", bundle: .module))
          .lineLimit(1)
        Image(systemName: "chevron.up.chevron.down")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 4)
    }
    // Alphabetical from the top, rather than flipped because the menu opens upward.
    .menuOrder(.fixed)
    .accessibilityLabel(String(localized: "Professor", bundle: .module))
    .accessibilityValue(viewModel.selectedProfessor?.name ?? String(localized: "All Professors", bundle: .module))
  }

  /// The loaded history knows which semester you took; until then, trust the summary's flag.
  private var isTaken: Bool {
    if let history = viewModel.course?.history {
      return history.contains { $0.myLectureID != nil }
    }
    return summary?.completed ?? false
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
