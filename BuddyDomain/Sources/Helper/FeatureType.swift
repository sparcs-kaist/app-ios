//
//  FeatureType.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/5/26.
//

import SwiftUI

public enum FeatureType: Int, CaseIterable, Sendable {
  case feed = 0
  case ara = 1
  case otl = 2
  case taxi = 3
  
  public var prettyString: LocalizedStringKey {
    switch self {
    case .ara:
      "Ara"
    case .feed:
      "Feed"
    case .otl:
      "OTL"
    case .taxi:
      "Taxi"
    }
  }
}
