//
//  Date+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import Foundation

extension Date {
  func timeAgoDisplay() -> String {
    let calendar = Calendar.current
    let now = Date()

    let components = calendar.dateComponents([.second, .minute, .hour, .day], from: self, to: now)

    if let day = components.day, day >= 7 {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      return dateFormatter.string(from: self)
    }

    if let day = components.day, day > 0 {
      return "\(day) day\(day > 1 ? "s" : "") ago"
    }

    if let hour = components.hour, hour > 0 {
      return "\(hour) hour\(hour > 1 ? "s" : "") ago"
    }

    if let minute = components.minute, minute > 0 {
      return "\(minute) min ago"
    }

    return "just now"
  }
  
  func ceilToNextTenMinutes() -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
    
    if let minute = components.minute {
      let remainder = minute % 10
      let minutesToAdd = remainder == 0 ? 0 : 10 - remainder
      components.minute! += minutesToAdd
      
      return calendar.date(from: components) ?? self
    } else {
      return self
    }
  }
}
