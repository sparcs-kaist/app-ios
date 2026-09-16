//
//  MockFoundationModelsUseCase.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation
import BuddyDomain

public actor MockFoundationModelsUseCase: FoundationModelsUseCaseProtocol {
  var isAvailableValue: Bool = false
  var summariseResult: String = ""
  /// The snapshots a generation streams, in order, as the real model's would
  /// arrive: partly filled in at first, complete by the last one.
  var themeBriefs: [TimetableThemeBrief] = []
  var themeBriefError: (any Error)?

  public init() { }

  public func isAvailable() async -> Bool {
    isAvailableValue
  }

  public func summarise(_ text: String, maxWords: Int, tone: String) async -> String {
    summariseResult
  }

  public func streamThemeBrief(
    describing description: String,
    variation: UInt64
  ) -> AsyncThrowingStream<TimetableThemeBrief, any Error> {
    let briefs = themeBriefs
    let error = themeBriefError
    return AsyncThrowingStream { continuation in
      for brief in briefs {
        continuation.yield(brief)
      }
      continuation.finish(throwing: error)
    }
  }

  /// Actors have no settable properties from the outside, so the stubs are set
  /// through here.
  public func stub(isAvailable: Bool? = nil, summarise: String? = nil) {
    if let isAvailable { isAvailableValue = isAvailable }
    if let summarise { summariseResult = summarise }
  }

  public func stub(themeBriefs: [TimetableThemeBrief] = [], error: (any Error)? = nil) {
    self.themeBriefs = themeBriefs
    self.themeBriefError = error
  }
}
