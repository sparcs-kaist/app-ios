//
//  CrashlyticsServiceProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 26/01/2026.
//

public protocol CrashlyticsServiceProtocol {
  func recordException(error: Error)
}
