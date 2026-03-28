//
//  Container.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Factory
import Foundation

extension Container {
  public var authService: Factory<AuthServicing?> {
    promised()
  }
}
