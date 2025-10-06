//
//  ContentViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import SwiftUI
import Combine
import Observation
import Factory
import BuddyDomain

@Observable
class ContentViewModel {
  @ObservationIgnored @Injected(
    \.tokenBridgeServiceWatch
  ) private var tokenBridgeServiceWatch: TokenBridgeServiceWatchProtocol

  @ObservationIgnored private var cancellables = Set<AnyCancellable>()

  var isAuthenticated: Bool = false

  func bind() {
    tokenBridgeServiceWatch.tokenStatePublisher
      .map { $0 != nil }
      .removeDuplicates()
      .sink { [weak self] newValue in
        self?.isAuthenticated = newValue
      }
      .store(in: &cancellables)
  }
}
