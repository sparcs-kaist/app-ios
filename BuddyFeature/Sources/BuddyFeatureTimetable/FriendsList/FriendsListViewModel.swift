//
//  FriendsListViewModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
final class FriendsListViewModel {
  // MARK: - State
  var viewState: FriendsListViewState = .loading

  /// The user's own invite code, or `nil` while loading / when the endpoint is
  /// unavailable (it 404s on production for now).
  var myCode: String?
  var isMyCodeUnavailable: Bool = false

  var alertState: AlertState?

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.friendUseCase) private var friendUseCase: FriendUseCaseProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(\.analyticsService) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Loading
  func load() async {
    guard let friendUseCase else { return }
    do {
      let list = try await friendUseCase.fetchFriends()
      apply(friends: list.friends)
      analyticsService?.logEvent(FriendsListViewEvent.friendsLoaded)
    } catch {
      crashlyticsService?.recordException(error: error)
      viewState = .error(message: error.localizedDescription)
    }
  }

  func loadMyCode() async {
    guard let friendUseCase else { return }
    do {
      myCode = try await friendUseCase.fetchMyCode()
      isMyCodeUnavailable = false
    } catch {
      // The code endpoint is not yet available everywhere; fail quietly and let
      // the view fall back rather than surfacing an alert.
      crashlyticsService?.recordException(error: error)
      myCode = nil
      isMyCodeUnavailable = true
    }
  }

  // MARK: - Mutations
  func addFriend(code: String) async {
    guard let friendUseCase, let normalized = FriendCode.normalized(code) else { return }
    do {
      try await friendUseCase.addFriend(code: normalized)
      analyticsService?.logEvent(FriendsListViewEvent.friendAdded)
      await load()
    } catch {
      crashlyticsService?.recordException(error: error)
      presentError(error)
    }
  }

  func delete(_ friend: Friend) async {
    guard let friendUseCase else { return }
    do {
      try await friendUseCase.deleteFriend(id: friend.id)
      analyticsService?.logEvent(FriendsListViewEvent.friendDeleted)
      await load()
    } catch {
      crashlyticsService?.recordException(error: error)
      presentError(error)
    }
  }

  func toggleFavorite(_ friend: Friend) async {
    guard let friendUseCase else { return }
    do {
      try await friendUseCase.setFavorite(id: friend.id, isFavorite: !friend.isFavorite)
      analyticsService?.logEvent(FriendsListViewEvent.favoriteToggled)
      await load()
    } catch {
      crashlyticsService?.recordException(error: error)
      presentError(error)
    }
  }

  // MARK: - Helpers

  /// Favourites float to the top, then everyone is ordered by name so the list
  /// stays stable across reloads.
  private func apply(friends: [Friend]) {
    guard !friends.isEmpty else {
      viewState = .empty
      return
    }
    let sorted = friends.sorted { lhs, rhs in
      if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
      return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
    viewState = .loaded(friends: sorted)
  }

  private func presentError(_ error: Error) {
    alertState = AlertState(
      title: String(localized: "Something Went Wrong", bundle: .module),
      message: error.localizedDescription
    )
  }
}
