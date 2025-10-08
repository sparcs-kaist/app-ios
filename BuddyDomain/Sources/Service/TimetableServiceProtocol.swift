//
//  TimetableServiceProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation

public protocol TimetableServiceProtocol {
  var timetableUseCase: TimetableUseCaseBackgroundProtocol? { get }

  func setup() async throws
}
