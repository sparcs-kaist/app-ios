//
//  TaxiRoomBlockStatus.swift
//  BuddyDomain
//
//  Created by 하정우 on 10/29/25.
//

import Foundation

public enum TaxiRoomBlockStatus: Equatable {
  case allow
  case notPaid
  case tooManyRooms
  case error(errorMessage: String)
}
