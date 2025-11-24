//
//  EnvironmentValues+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 26/07/2025.
//

import SwiftUI
import BuddyDomain

struct TaxiUserKey: EnvironmentKey {
  static let defaultValue: TaxiUser? = nil
}

private struct WindowSizeClassKey: EnvironmentKey {
  static let defaultValue: UserInterfaceSizeClass? = .regular
}

extension EnvironmentValues {
  var taxiUser: TaxiUser? {
    get { self[TaxiUserKey.self] }
    set { self[TaxiUserKey.self] = newValue }
  }
  
  var windowSizeClass: UserInterfaceSizeClass? {
    get { self[WindowSizeClassKey.self] }
    set { self[WindowSizeClassKey.self] = newValue }
  }
}
