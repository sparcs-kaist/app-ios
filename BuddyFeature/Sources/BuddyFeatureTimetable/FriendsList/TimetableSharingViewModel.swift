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
  /// Semesters whose choice is being saved; their choices wait until it's done.
  private(set) var savingSemesters: Set<String> = []
  var alertState: AlertState?

  /// Per semester, bumped by every load and every change, so an answer to an older
  /// request, such as a load that began before the user chose, can't replace a newer one.
  @ObservationIgnored private var requestGenerations: [String: Int] = [:]
  /// Per semester, what the server last confirmed, to fall back to if a change fails.
  @ObservationIgnored private var confirmed: [String: TimetableSharing] = [:]

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
    // A save under way already knows the newest choice; a load now could return the old one.
    guard let sharingUseCase, !savingSemesters.contains(semester.id) else { return }
    let request = nextRequest(for: semester)
    if case .loaded = sharings[semester.id] {} else { sharings[semester.id] = .loading }
    do {
      let sharing = try await sharingUseCase.fetchSharing(semester: semester)
      guard isLatest(request, for: semester) else { return }
      confirmed[semester.id] = sharing
      sharings[semester.id] = .loaded(sharing)
    } catch {
      guard isLatest(request, for: semester) else { return }
      crashlyticsService?.recordException(error: error)
      sharings[semester.id] = .error(message: error.localizedDescription)
    }
  }

  func isSaving(_ semester: Semester) -> Bool {
    savingSemesters.contains(semester.id)
  }

  private func nextRequest(for semester: Semester) -> Int {
    let next = (requestGenerations[semester.id] ?? 0) + 1
    requestGenerations[semester.id] = next
    return next
  }

  private func isLatest(_ request: Int, for semester: Semester) -> Bool {
    requestGenerations[semester.id] == request
  }

  /// Shares `timetableID`, or the enrolled lectures when it's `nil`. The checkmark moves
  /// at once and moves back if the server refuses.
  /// One change per semester at a time, so two can't reach the server out of order.
  func share(_ timetableID: Int?, semester: Semester) async {
    guard let sharingUseCase, !savingSemesters.contains(semester.id),
          case .loaded(let sharing) = sharing(for: semester),
          sharing.sharedTimetableID != timetableID else { return }
    savingSemesters.insert(semester.id)
    defer { savingSemesters.remove(semester.id) }
    // Turns away any load already under way: it may answer with the choice from before.
    let request = nextRequest(for: semester)
    let chosen = sharing.sharing(timetableID)
    sharings[semester.id] = .loaded(chosen)
    do {
      try await sharingUseCase.share(timetableID: timetableID, semester: semester)
      confirmed[semester.id] = chosen
      analyticsService?.logEvent(FriendsListViewEvent.sharedTimetableChanged)
    } catch {
      crashlyticsService?.recordException(error: error)
      if isLatest(request, for: semester) {
        sharings[semester.id] = .loaded(confirmed[semester.id] ?? sharing)
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
