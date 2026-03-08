//
//  TaxiListViewState.swift
//  BuddyDomain
//
//  Created by 하정우 on 3/6/26.
//

import Foundation

public enum TaxiListViewState {
  case loading
  case loaded(rooms: [TaxiRoom], locations: [TaxiLocation])
  case empty
  case error(message: String)
}
