//
//  FoundationModelsUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

@MainActor
public protocol FoundationModelsUseCaseProtocol {
  var isAvailable: Bool { get }

  func summarise(_ text: String, maxWords: Int, tone: String) async -> String
}
