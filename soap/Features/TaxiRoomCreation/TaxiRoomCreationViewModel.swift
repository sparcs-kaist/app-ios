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
  var roomName = ""
}
