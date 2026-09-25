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
}

@MainActor
@Observable
final class CreditCalculationViewModel {
  @ObservationIgnored @Injected(\.v2LectureUseCase) private var lectureUseCase: LectureUseCaseProtocol?
  @ObservationIgnored @Injected(\.v2TimetableUseCase) private var timetableUseCase: TimetableUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  private(set) var state: CreditCalculationViewState = .loading
  private(set) var semesters: [TakenSemester] = []
  private(set) var timetables: [String: Timetable] = [:]

  /// Semesters whose table is loading or already loaded, so cells scrolling
  /// back into view don't refetch.
  @ObservationIgnored private var requestedTimetableIDs: Set<String> = []

  init() {}

  /// Starts already loaded with fixed data, for previews.
  init(semesters: [TakenSemester], timetables: [String: Timetable]) {
    self.state = .loaded
    self.semesters = semesters
    self.timetables = timetables
    self.requestedTimetableIDs = Set(semesters.map(\.id))
  }

  func load() async {
    // Only the initial load and a retry after an error fetch; seeded data stays.
    guard state != .loaded else { return }
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
    } catch is CancellationError {
      return
    } catch {
      state = .error(message: error.localizedDescription)
    }
  }

  /// Lazily fetches a semester's "My Table" when its cell first appears.
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
