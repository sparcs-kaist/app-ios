//
//  AuthTokenRefreshCoordinator.swift
//  BuddyData
//

import Foundation
import Darwin
import BuddyDomain

/// Shares a single refresh operation among callers using the same refresh token.
public actor AuthTokenRefreshCoordinator {
  public static let shared = AuthTokenRefreshCoordinator()

  private var inFlight: [String: Task<TokenResponse, Error>] = [:]
  private var hasExclusiveAccess = false
  private var exclusiveAccessWaiters: [CheckedContinuation<Void, Never>] = []

  public func refresh(
    refreshToken: String,
    tokenStorage: TokenStorageProtocol,
    operation: @escaping @Sendable () async throws -> TokenResponse
  ) async throws -> TokenResponse {
    if let existing = inFlight[refreshToken] {
      return try await existing.value
    }

    let task = Task {
      try await self.withExclusiveAccess {
        guard let currentRefreshToken = try tokenStorage.readRefreshToken() else {
          throw NetworkError.unauthorized
        }
        if currentRefreshToken != refreshToken {
          guard let currentAccessToken = tokenStorage.getAccessToken() else {
            throw NetworkError.unauthorized
          }
          return TokenResponse(accessToken: currentAccessToken, refreshToken: currentRefreshToken)
        }

        let response = try await operation()
        try tokenStorage.save(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
      }
    }
    inFlight[refreshToken] = task
    defer { inFlight[refreshToken] = nil }

    return try await task.value
  }

  public func withExclusiveAccess<T: Sendable>(
    operation: @escaping @Sendable () async throws -> T
  ) async throws -> T {
    await acquireExclusiveAccess()
    defer { releaseExclusiveAccess() }
    return try await Task.detached {
      try await RefreshTokenFileLock.withLock(operation: operation)
    }.value
  }

  private func acquireExclusiveAccess() async {
    guard hasExclusiveAccess else {
      hasExclusiveAccess = true
      return
    }
    await withCheckedContinuation { continuation in
      exclusiveAccessWaiters.append(continuation)
    }
  }

  private func releaseExclusiveAccess() {
    if exclusiveAccessWaiters.isEmpty {
      hasExclusiveAccess = false
    } else {
      exclusiveAccessWaiters.removeFirst().resume()
    }
  }
}

private enum RefreshTokenFileLock {
  static func withLock<T: Sendable>(
    operation: @escaping @Sendable () async throws -> T
  ) async throws -> T {
    guard let sharedContainer = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.org.sparcs.soap"
    ) else {
      return try await operation()
    }

    let lockURL = sharedContainer.appendingPathComponent("auth-token-refresh.lock")
    let descriptor = lockURL.path.withCString {
      Darwin.open($0, O_CREAT | O_RDWR, 0o600)
    }
    guard descriptor >= 0 else {
      throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
    }

    var lock = flock()
    lock.l_type = Int16(F_WRLCK)
    lock.l_whence = Int16(SEEK_SET)
    lock.l_start = 0
    lock.l_len = 0

    while Darwin.fcntl(descriptor, F_SETLKW, &lock) == -1 {
      guard errno == EINTR else {
        let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        Darwin.close(descriptor)
        throw error
      }
    }
    defer {
      lock.l_type = Int16(F_UNLCK)
      _ = Darwin.fcntl(descriptor, F_SETLK, &lock)
      Darwin.close(descriptor)
    }

    return try await operation()
  }
}
