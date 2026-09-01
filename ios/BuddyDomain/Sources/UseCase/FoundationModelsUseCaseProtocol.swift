//
//  FoundationModelsUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol FoundationModelsUseCaseProtocol: Actor {
  func isAvailable() async -> Bool
  func summarise(_ text: String, maxWords: Int, tone: String) async -> String
}
