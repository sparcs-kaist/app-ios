//
//  SearchViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import SwiftUI
import Observation

@Observable
class SearchViewModel {
  var searchText: String = ""
  var searchScope: SearchScope = .all
}
