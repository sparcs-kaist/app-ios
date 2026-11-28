//
//  TimetableSharingViewModel.swift
//  BuddyFeature
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

/// Backs both the semester list and each semester's page, so a choice made on a
/// page shows in the list as soon as the user goes back.
@MainActor
@Observable
final class TimetableSharingViewModel {
  enum ListState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }

  // MARK: - State
  private(set) var listState: ListState = .loading
  /// The semesters with something to share, newest first.
  private(set) var semesters: [Semester] = []
  /// Each semester's choices and which one friends see, by `Semester.id`.
  private(set) var sharings: [String: TimetableSharingViewState] = [:]
  /// What each choice looks like, by `previewKey`. `nil` while it loads.
  private(set) var previews: [String: Timetable] = [:]
  var alertState: AlertState?

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.v2TimetableUseCase) private var timetableUseCase: TimetableUseCaseProtocol?
  @ObservationIgnored @Injected(\.timetableSharingUseCase) private var sharingUseCase: TimetableSharingUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(\.analyticsService) private var analyticsService: AnalyticsServiceProtocol?

  /// Lists the semesters with the user's timetables or enrolled lectures, and the current
  /// one even when it has neither, since that's the one friends look at most.
  func load() async {
    guard let timetableUseCase, let sharingUseCase else { return }
    do {
      async let all = timetableUseCase.getSemesters()
      async let terms = sharingUseCase.fetchSharableTerms()
      let current = try? await timetableUseCase.getCurrentSemesters()
      let sharable = try await terms
      semesters = try await all
        .filter { $0 == current || sharable.contains(FriendTimetableTerm(year: $0.year, semester: $0.semesterType)) }
        .sorted(by: >)
      listState = .loaded
    } catch {
      crashlyticsService?.recordException(error: error)
      listState = .error(message: error.localizedDescription)
    }
  }

  func sharing(for semester: Semester) -> TimetableSharingViewState {
    sharings[semester.id] ?? .loading
  }

  /// The name friends see for `semester`, for the list's trailing text.
  func sharedName(for semester: Semester) -> String? {
    guard case .loaded(let sharing) = sharing(for: semester) else { return nil }
    guard let id = sharing.sharedTimetableID else {
      return String(localized: "Enrolled Lectures", bundle: .module)
    }
    return sharing.timetables.first { $0.id == id }.map(Self.title(of:))
  }

  func loadSharing(for semester: Semester) async {
    guard let sharingUseCase else { return }
    if case .loaded = sharings[semester.id] {} else { sharings[semester.id] = .loading }
    do {
      sharings[semester.id] = .loaded(try await sharingUseCase.fetchSharing(semester: semester))
    } catch {
      crashlyticsService?.recordException(error: error)
      sharings[semester.id] = .error(message: error.localizedDescription)
    }
  }

  /// Shares `timetableID`, or the enrolled lectures when it's `nil`. The checkmark moves
  /// at once and moves back if the server refuses.
  func share(_ timetableID: Int?, semester: Semester) async {
    guard let sharingUseCase, case .loaded(let sharing) = sharing(for: semester),
          sharing.sharedTimetableID != timetableID else { return }
    sharings[semester.id] = .loaded(sharing.sharing(timetableID))
    do {
      try await sharingUseCase.share(timetableID: timetableID, semester: semester)
      analyticsService?.logEvent(FriendsListViewEvent.sharedTimetableChanged)
    } catch {
      crashlyticsService?.recordException(error: error)
      if case .loaded(let shown) = sharings[semester.id], shown.sharedTimetableID == timetableID {
        sharings[semester.id] = .loaded(sharing)
      }
      alertState = AlertState(
        title: String(localized: "Couldn’t Change Sharing", bundle: .module),
        message: error.localizedDescription
      )
    }
  }

  // MARK: - Preview

  func preview(of timetableID: Int?, in semester: Semester) -> Timetable? {
    previews[Self.previewKey(timetableID, semester)]
  }

  /// Loads what friends would see for a choice: the timetable itself, or the enrolled lectures.
  func loadPreview(of timetableID: Int?, in semester: Semester) async {
    guard let timetableUseCase else { return }
    let key = Self.previewKey(timetableID, semester)
    guard previews[key] == nil else { return }
    do {
      previews[key] = if let timetableID {
        try await timetableUseCase.getTable(id: timetableID)
      } else {
        try await timetableUseCase.getMyTable(semester: semester)
      }
    } catch {
      // The choice can still be made without a preview; the grid stays empty.
      crashlyticsService?.recordException(error: error)
      previews[key] = Timetable(id: key, lectures: [])
    }
  }

  static func title(of timetable: TimetableSummary) -> String {
    timetable.title.isEmpty ? String(localized: "Untitled", bundle: .module) : timetable.title
  }

  private static func previewKey(_ timetableID: Int?, _ semester: Semester) -> String {
    timetableID.map { "table-\($0)" } ?? "enrolled-\(semester.id)"
  }
}
