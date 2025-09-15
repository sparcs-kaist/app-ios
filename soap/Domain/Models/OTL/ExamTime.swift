//
//  ExamTime.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

struct ExamTime {
  let description: LocalizedString
  let day: DayType
  let begin: Int
  let end: Int

  var duration: Int {
    end - begin
  }
}
