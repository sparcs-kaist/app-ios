//
//  FriendTimetableViewModel.swift
//  BuddyFeature
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
final class FriendTimetableViewModel {
  let friend: Friend

  // MARK: - State
  var viewState: FriendTimetableViewState = .loading
  /// The semesters the friend has a timetable for, newest first.
  private(set) var terms: [FriendTimetableTerm] = []
  private(set) var selectedTerm: FriendTimetableTerm?
  /// A timetable request is in flight. The table already on screen stays there meanwhile,
  /// so switching semesters swaps one table for the next instead of flashing a spinner.
  private(set) var isLoadingTimetable = false

  /// Bumped for every timetable request, so a slow answer for a semester the user
  /// has since moved off can't replace the one now selected.
  @ObservationIgnored private var generation = 0

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.friendUseCase) private var friendUseCase: FriendUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(\.analyticsService) private var analyticsService: AnalyticsServiceProtocol?

  /// - Parameter term: The semester to open on, such as the one a shared lecture is in.
  ///   Defaults to the newest.
  init(friend: Friend, term: FriendTimetableTerm? = nil) {
    self.friend = friend
    self.selectedTerm = term
  }

  /// Loads the friend's semesters, then the selected one's timetable. Opens on the
  /// newest semester, as the web does, and keeps the selection across reloads.
  func load() async {
    guard let friendUseCase else { return }
    do {
      let terms = try await friendUseCase.fetchSharedTimetableTerms(friendID: friend.id)
      self.terms = terms
      guard let term = selectedTerm.flatMap({ terms.contains($0) ? $0 : nil }) ?? terms.first else {
        selectedTerm = nil
        viewState = .empty
        return
      }
      await show(term)
    } catch {
      crashlyticsService?.recordException(error: error)
      viewState = .error(message: error.localizedDescription)
    }
  }

  func select(_ term: FriendTimetableTerm) async {
    guard term != selectedTerm, terms.contains(term) else { return }
    analyticsService?.logEvent(FriendTimetableViewEvent.semesterChanged)
    await show(term)
  }

  func lectureOpened() {
    analyticsService?.logEvent(FriendTimetableViewEvent.lectureOpened)
  }

  private func show(_ term: FriendTimetableTerm) async {
    guard let friendUseCase else { return }
    generation += 1
    let request = generation
    if case .loaded = viewState {} else { viewState = .loading }
    selectedTerm = term
    isLoadingTimetable = true
    do {
      let timetable = try await friendUseCase.fetchSharedTimetable(friendID: friend.id, term: term)
      guard request == generation else { return }
      isLoadingTimetable = false
      viewState = .loaded(timetable)
      analyticsService?.logEvent(FriendTimetableViewEvent.timetableLoaded)
    } catch {
      guard request == generation else { return }
      isLoadingTimetable = false
      crashlyticsService?.recordException(error: error)
      viewState = .error(message: error.localizedDescription)
    }
  }
}
