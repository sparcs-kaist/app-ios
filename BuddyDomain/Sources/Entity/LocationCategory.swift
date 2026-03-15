//
//  LocationCategory.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 15/03/2026.
//

import Foundation
import SwiftUI

public enum LocationCategory: Hashable {
  case building
  case academicBuilding
  case parking
  case cafe
  case gate
  case restaurant
  case cafeteria
  case dormitory
  case library
  case sportsField
  case hospital
  case olevStop
  case store

  public var color: Color {
    switch self {
    case .building:
        .brown
    case .academicBuilding:
        .brown
    case .parking:
        .blue
    case .cafe:
        .orange
    case .gate:
        .gray
    case .restaurant:
        .orange
    case .cafeteria:
        .orange
    case .dormitory:
        .purple
    case .library:
        .brown
    case .sportsField:
        .green
    case .hospital:
        .red
    case .olevStop:
        .blue
    case .store:
        .yellow
    }
  }

  public var symbol: String {
    switch self {
    case .building:
      "building.fill"
    case .academicBuilding:
      "graduationcap.fill"
    case .parking:
      "parkingsign"
    case .cafe:
      "cup.and.saucer.fill"
    case .gate:
      "door.left.hand.open"
    case .restaurant:
      "fork.knife"
    case .cafeteria:
      "fork.knife"
    case .dormitory:
      "bed.double.fill"
    case .library:
      "book.fill"
    case .sportsField:
      "sportscourt.fill"
    case .hospital:
      "cross.fill"
    case .olevStop:
      "bus.fill"
    case .store:
      "cart.fill"
    }
  }
}
