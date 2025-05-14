//
//  TaxiRoomCreationViewModel.swift
//  soap
//
//  Created by 김민찬 on 3/23/25.
//

import Foundation

@Observable
class TaxiRoomCreationViewModel {
  var roomDepatureTime = Date().ceilToNextTenMinutes()
  var roomCapacity = 4
  var roomName = "new room"

  var origin: TaxiLocation?
  var destination: TaxiLocation?
  var locations: [TaxiLocation] = TaxiLocation.mockList
  
//  static var randomRoomNames = [
//    "방 이름 1",
//    "방 이름 2",
//    "방 이름 3",
//  ]
}
