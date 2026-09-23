//
//  TimetablePlacement.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation

public enum TimetablePlacement: Equatable, Sendable {
  case view
  case widget
  /// Static export with solid cells and professor descriptions.
  case render
}
