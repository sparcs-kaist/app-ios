//
//  SearchScope.swift
//  soap
//
//  Created by Soongyu Kwon on 28/09/2025.
//

import SwiftUI

public enum SearchScope: String, Codable, CaseIterable, Identifiable, Hashable {
  case all = "All"
  case courses = "Courses"
  case posts = "Posts"
  case taxi = "Rides"
  public var id: String { rawValue }

  public var description: String {
    switch self {
    case .all:
      String(localized: "All", bundle: .module)
    case .courses:
      String(localized: "Courses", bundle: .module)
    case .posts:
      String(localized: "Posts", bundle: .module)
    case .taxi:
      String(localized: "Rides", bundle: .module)
    }
  }
}
