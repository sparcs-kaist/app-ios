//
//  MockAuthUseCase.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Foundation
import BuddyDomain
import Combine

public final class MockAuthUseCase: AuthUseCaseProtocol, @unchecked Sendable {
  var signOutResult: Result<Void, Error> = .success(())
  public var signOutCallCount = 0

  public nonisolated var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
    Just(true).eraseToAnyPublisher()
  }

  public init() { }

  public func signIn() async throws {}
  public func signOut() async throws {
    signOutCallCount += 1
    try signOutResult.get()
  }
  public func getAccessToken() -> String? { nil }
  public func getValidAccessToken() async throws -> String { "" }
  public func refreshAccessToken(force: Bool) async throws {}
}
