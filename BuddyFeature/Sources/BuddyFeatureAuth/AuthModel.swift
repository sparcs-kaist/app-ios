//
//  AuthModel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
public final class AuthModel {
  @ObservationIgnored
  @Injected(\.authService) private var authService: AuthServicing?

  public var isBootstrapping: Bool = true
  public var isAuthenticated: Bool = false

  public init() { }

  public func bootstrap() async {
    guard let authService else { return }

    let authenticated = await authService.bootstrap()
    isAuthenticated = authenticated
    isBootstrapping = false
  }

  public func login() async {
    guard let authService else { return }

    do {
      try await authService.login()
      isAuthenticated = true
    } catch {
      print(error)
    }
  }
}
