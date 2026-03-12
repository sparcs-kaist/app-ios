//
//  TimetableSummaryListDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import BuddyDomain

struct TimetableSummaryListDTO: Codable {
  let timetables: [TimetableSummaryDTO]
}
