//
//  CreditCalculationViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

/// One semester the user has taken lectures in.
struct TakenSemester: Identifiable, Hashable {
  let id: String
  let title: String
  /// The matching OTL semester, needed to fetch its "My Table". `nil` when the
  /// semester list does not include it; the cell then shows an empty silhouette.
  let semester: Semester?

  /// Compact axis label such as "24S", from the "year-Type" `id`; falls back to `title`.
  var shortTitle: String {
    let parts = id.split(separator: "-")
    guard parts.count == 2, let type = SemesterType(rawValue: String(parts[1])) else { return title }
    return "\(parts[0].suffix(2))\(type.shortCode)"
  }
}

/// One point on the GPA trend chart.
struct SemesterGPA: Identifiable, Equatable {
  let id: String
  let label: String
  let title: String
  let gpa: Double
}

@MainActor
@Observable
final class CreditCalculationViewModel {
  @ObservationIgnored @Injected(\.v2LectureUseCase) private var lectureUseCase: LectureUseCaseProtocol?
  @ObservationIgnored @Injected(\.v2TimetableUseCase) private var timetableUseCase: TimetableUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(\.lectureGradeUseCase) private var lectureGradeUseCase: LectureGradeUseCaseProtocol?

  private(set) var state: CreditCalculationViewState = .loading
  private(set) var semesters: [TakenSemester] = []
  private(set) var timetables: [String: Timetable] = [:]
  /// Grades the user entered, keyed by lecture ID.
  private(set) var grades: [Int: LectureGrade] = [:]

  /// The signed-in OTL user; grades are stored per user.
  @ObservationIgnored private var userID: Int?
  /// The user's majors, listed first in the credit breakdown.
  private(set) var majorDepartments: [Department] = []
  /// Minimum credits per requirement type; defaults until the user edits them.
  private(set) var requirements = CreditRequirements()
  @ObservationIgnored private let requirementsStore = CreditRequirementsStore()

  /// Semesters whose table is loading or already loaded, so cells appearing
  /// don't refetch.
  @ObservationIgnored private var requestedTimetableIDs: Set<String> = []

  init() {}

  /// Starts already loaded with fixed data, for previews.
  init(
    semesters: [TakenSemester],
    timetables: [String: Timetable],
    grades: [Int: LectureGrade] = [:],
    majorDepartments: [Department] = []
  ) {
    self.state = .loaded
    self.majorDepartments = majorDepartments
    self.semesters = semesters
    self.timetables = timetables
    self.grades = grades
    self.requestedTimetableIDs = Set(semesters.map(\.id))
  }

  func load() async {
    // Only the initial load and a retry after an error fetch; seeded data stays.
    guard state != .loaded else { return }
    // Also shows the skeleton again when retrying after an error.
    state = .loading
    guard let lectureUseCase, let timetableUseCase, let userUseCase else {
      state = .error(message: String(localized: "Unexpected Error", bundle: .module))
      return
    }

    do {
      if await userUseCase.otlUser == nil {
        try await userUseCase.fetchOTLUser()
      }
      guard let user = await userUseCase.otlUser else {
        state = .error(message: String(localized: "Unexpected Error", bundle: .module))
        return
      }
      userID = user.id
      majorDepartments = user.majorDepartments
      requirements = requirementsStore.requirements(userID: user.id)
      // Grades are on-device; a failure here shouldn't block the semester list.
      grades = (try? await lectureGradeUseCase?.grades(userID: user.id)) ?? [:]

      async let history = lectureUseCase.fetchUserLectureHistory(userID: user.id)
      async let allSemesters = timetableUseCase.getSemesters()
      let semestersByID = Dictionary(
        try await allSemesters.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
      )

      // The history's semester IDs share `Semester.id`'s "year-Type" format.
      semesters = try await history.semesters
        .filter { !$0.lectures.isEmpty }
        .sorted { ($0.year, $0.semesterType.intValue) < ($1.year, $1.semesterType.intValue) }
        .map { entry in
          TakenSemester(
            id: entry.id,
            title: "\(entry.year) \(entry.semesterType.description)",
            semester: semestersByID[entry.id]
          )
        }
      state = .loaded
      // The summary at the top needs every semester, not just the cards on screen.
      await loadAllTimetables()
    } catch is CancellationError {
      return
    } catch {
      state = .error(message: error.localizedDescription)
    }
  }

  /// Cumulative GPA and credits across every semester.
  var overallSummary: SemesterGradeSummary {
    SemesterGradeSummary(lectures: semesters.flatMap { timetables[$0.id]?.lectures ?? [] }, grades: grades)
  }

  /// Credits taken per requirement type across every semester.
  var creditBreakdown: CreditBreakdown {
    CreditBreakdown(
      lectures: semesters.flatMap { timetables[$0.id]?.lectures ?? [] },
      grades: grades,
      majorDepartments: majorDepartments
    )
  }

  /// Whether every semester's table has loaded, so `overallSummary` isn't a partial total.
  var isOverallSummaryReady: Bool {
    state == .loaded && semesters.allSatisfy { $0.semester == nil || timetables[$0.id] != nil }
  }

  /// Each semester's GPA in order, skipping semesters with no GPA yet.
  var gpaTrend: [SemesterGPA] {
    semesters.compactMap { item in
      summary(for: item)?.gpa.map { SemesterGPA(id: item.id, label: item.shortTitle, title: item.title, gpa: $0) }
    }
  }

  func summary(for item: TakenSemester) -> SemesterGradeSummary? {
    timetables[item.id].map { SemesterGradeSummary(lectures: $0.lectures, grades: grades) }
  }

  func updateRequirements(_ requirements: CreditRequirements) {
    self.requirements = requirements
    guard let userID else { return }
    requirementsStore.save(requirements, userID: userID)
  }

  /// Updates the grade immediately and persists it, reverting if saving fails.
  func setGrade(_ grade: LectureGrade?, lectureID: Int) {
    let previous = grades[lectureID]
    grades[lectureID] = grade
    guard let lectureGradeUseCase, let userID else { return }

    Task {
      do {
        try await lectureGradeUseCase.setGrade(grade, lectureID: lectureID, userID: userID)
      } catch {
        // Skip the revert if the user already picked something newer.
        if grades[lectureID] == grade { grades[lectureID] = previous }
      }
    }
  }

  private func loadAllTimetables() async {
    await withTaskGroup(of: Void.self) { group in
      for item in semesters {
        group.addTask { await self.loadTimetable(for: item) }
      }
    }
  }

  /// Fetches a semester's "My Table" once. Also called when its cell appears,
  /// which retries a table whose earlier fetch failed.
  func loadTimetable(for item: TakenSemester) async {
    guard let semester = item.semester, let timetableUseCase,
          requestedTimetableIDs.insert(item.id).inserted else { return }

    do {
      timetables[item.id] = try await timetableUseCase.getMyTable(semester: semester)
    } catch {
      // Allow a retry the next time the cell appears.
      requestedTimetableIDs.remove(item.id)
    }
  }
}
