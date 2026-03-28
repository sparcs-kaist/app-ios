//
//  RefreshCoordinator.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation
import BuddyDomain

actor RefreshCoordinator {
  private var refreshTask: Task<TokenPair, Error>?

  func refreshIfNeeded(
    operation: @escaping @Sendable () async throws -> TokenPair
  ) async throws -> TokenPair {
    if let refreshTask {
      return try await refreshTask.value
    }

    let task = Task {
      try await operation()
    }

    refreshTask = task
    defer { refreshTask = nil }

    return try await task.value
  }
}
