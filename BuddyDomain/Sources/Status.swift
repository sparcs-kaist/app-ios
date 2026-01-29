//
//  Status.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 23/12/2025.
//

import Foundation

public enum Status {
  // App Status
  public static let isProduction: Bool = {
    // Custom status
    return true

    #if DEBUG
    return false
    #else
    return true
    #endif
  }()
}
