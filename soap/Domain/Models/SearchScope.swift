//
//  SearchScope.swift
//  soap
//
//  Created by Soongyu Kwon on 28/09/2025.
//

import SwiftUI

enum SearchScope: String, Codable, CaseIterable, Identifiable, Hashable {
  case all = "All"
  case courses = "Courses"
  case posts = "Posts"
  case taxi = "Rides"
  var id: String { rawValue }
}
