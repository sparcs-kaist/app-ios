//
//  TestError.swift
//  BuddyTestSupport
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import Foundation

public enum TestError: Error, LocalizedError {
  case testFailure
  case notConfigured

  public var errorDescription: String? {
    switch self {
    case .testFailure: return "Test failure"
    case .notConfigured: return "Not configured"
    }
  }
}
