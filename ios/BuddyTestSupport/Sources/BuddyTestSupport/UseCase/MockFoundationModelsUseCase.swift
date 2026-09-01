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

  public init() { }

  public func isAvailable() async -> Bool {
    isAvailableValue
  }

  public func summarise(_ text: String, maxWords: Int, tone: String) async -> String {
    summariseResult
  }
}
