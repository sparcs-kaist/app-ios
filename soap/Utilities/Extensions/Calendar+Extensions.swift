//
//  Calendar+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import Foundation

extension Calendar {
  func startOfWeek(for date: Date) -> Date {
    let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)

    return self.date(from: components) ?? date
  }
}
