//
//  BlockedUsersView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 26/10/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "BlockedUsersView")

/// Everyone the user has blocked on Ara, to unblock.
public struct BlockedUsersView: View {
  @State private var model = BlockedUsersModel()

  public init() { }

  public var body: some View {
    Group {
      switch model.state {
      case .loading:
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .failed(let message):
        ContentUnavailableView {
          Label(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark")
        } description: {
          Text(message)
        } actions: {
          Button(String(localized: "Try Again", bundle: .module)) {
            Task { await model.load() }
          }
        }
      case .loaded(let users) where users.isEmpty:
        ContentUnavailableView(
          String(localized: "No Blocked Users", bundle: .module),
          systemImage: "person.crop.circle.badge.checkmark",
          description: Text("People you block from a post or comment appear here.", bundle: .module)
        )
      case .loaded(let users):
        List {
          Section {
            ForEach(users) { user in
              BlockedUserRow(user: user) {
                Task { await model.unblock(user) }
              }
            }
          } footer: {
            Text("You don't see their posts or comments on Ara.", bundle: .module)
          }
        }
        .animation(.default, value: users)
      }
    }
    .navigationTitle(String(localized: "Blocked Users", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .alert(
      model.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $model.isAlertPresented
    ) {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    } message: {
      Text(model.alertState?.message ?? "")
    }
    .task { await model.load() }
    .refreshable { await model.load() }
  }
}

private struct BlockedUserRow: View {
  let user: AraBlockedUser
  let onUnblock: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      PostAuthorAvatar(url: user.profilePictureURL, size: 32)
      Text(user.nickname)
        .lineLimit(1)
      Spacer()
      Button(String(localized: "Unblock", bundle: .module), action: onUnblock)
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
    .swipeActions {
      Button(String(localized: "Unblock", bundle: .module), action: onUnblock)
        .tint(.accentColor)
    }
  }
}

/// The block list, and unblocking from it.
@MainActor
@Observable
final class BlockedUsersModel {
  enum State: Equatable {
    case loading
    case loaded([AraBlockedUser])
    case failed(message: String)
  }

  private(set) var state: State = .loading
  var alertState: AlertState?
  var isAlertPresented = false

  @ObservationIgnored @Injected(\.araUserRepository) private var araUserRepository: AraUserRepositoryProtocol?
  @ObservationIgnored @Injected(\.analyticsService) private var analyticsService: AnalyticsServiceProtocol?

  func load() async {
    guard let araUserRepository else { return }
    if case .failed = state { state = .loading }
    do {
      state = .loaded(try await araUserRepository.fetchBlockedUsers())
    } catch {
      logger.error("Failed to fetch blocked users: \(error.localizedDescription, privacy: .public)")
      // A refresh that fails keeps the list already shown.
      if case .loaded = state { return }
      state = .failed(message: String(localized: "Failed to load blocked users.", bundle: .module))
    }
  }

  /// Takes `user` off the list straight away, and puts them back if Ara refuses.
  func unblock(_ user: AraBlockedUser) async {
    guard let araUserRepository, case .loaded(let users) = state else { return }
    state = .loaded(users.filter { $0.id != user.id })
    do {
      try await araUserRepository.unblockUser(userID: user.id)
      analyticsService?.logEvent(BlockedUsersViewEvent.userUnblocked)
    } catch {
      logger.error("Failed to unblock user: \(error.localizedDescription, privacy: .public)")
      if case .loaded(let current) = state, !current.contains(user) {
        state = .loaded(users.filter { $0 == user || current.contains($0) })
      }
      alertState = .init(
        title: String(localized: "Unable to unblock author.", bundle: .module),
        message: error.localizedDescription
      )
      isAlertPresented = true
    }
  }
}

enum BlockedUsersViewEvent: Event {
  case userUnblocked

  var source: String { "BlockedUsersView" }

  var name: String {
    switch self {
    case .userUnblocked: "blocked_user_unblocked"
    }
  }

  var parameters: [String: Any] { ["source": source] }
}
