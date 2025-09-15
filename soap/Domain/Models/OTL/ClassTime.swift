//
//  ClassTime.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

struct ClassTime {
  let buildingCode: String
  let classroomName: LocalizedString
  let classroomNameShort: LocalizedString
  let roomName: String
  let day: DayType
  let begin: Int
  let end: Int

  var duration: Int {
    end - begin
  }
}
