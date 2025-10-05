//
//  Date+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import Foundation

extension Date {
  var timeAgoDisplay: String {
    let calendar = Calendar.current
    let now = Date()

    let components = calendar.dateComponents([.second, .minute, .hour, .day], from: self, to: now)

    if let day = components.day, day >= 7 {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      return dateFormatter.string(from: self)
    }

    if let day = components.day, day > 0 {
      return String(localized: "\(day) day\(day > 1 ? "s" : "") ago")
    }

    if let hour = components.hour, hour > 0 {
      return String(localized: "\(hour) hour\(hour > 1 ? "s" : "") ago")
    }

    if let minute = components.minute, minute > 0 {
      return String(localized: "\(minute) min ago")
    }

    return String(localized: "just now")
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

  var formattedString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.setLocalizedDateFormatFromTemplate("yMMMMdEEEjm")
    return formatter.string(from: self)
  }

  var formattedTime: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.setLocalizedDateFormatFromTemplate("jm") // e.g., 3:30 PM
    return formatter.string(from: self)
  }

  var formattedDate: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.setLocalizedDateFormatFromTemplate("MMMM d, EEE") // e.g., July 18, Thu
    return formatter.string(from: self)
  }

  var relativeTimeString: String {
    let calendar = Calendar.current

    if calendar.isDateInToday(self) {
      return String(localized: "Today at \(self.localizedTime)")
    } else if calendar.isDateInTomorrow(self) {
      return String(localized: "Tomorrow at \(self.localizedTime)")
    } else if let weekday = self.weekdayNameIfWithinAWeek {
      return String(localized: "\(weekday) at \(self.localizedTime)")
    }

    return self.formatted(.dateTime
      .year().month().day()
      .hour().minute())
  }

  private var localizedTime: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeStyle = .short
    return formatter.string(from: self)
  }

  private var weekdayNameIfWithinAWeek: String? {
    let calendar = Calendar.current
    let now = Date()
    let nowWeekStart = calendar.startOfDay(for: now)
    let selfWeekStart = calendar.startOfDay(for: self)

    guard let days = calendar.dateComponents([.day], from: nowWeekStart, to: selfWeekStart).day,
          days > 0 && days < 7 else { return nil }

    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.setLocalizedDateFormatFromTemplate("EEEE")
    return formatter.string(from: self)
  }

  var weekdaySymbol: String {
    let calendar = Calendar.current
    let weekdayIndex = calendar.component(.weekday, from: self) - 1
    return calendar.weekdaySymbols[weekdayIndex]
  }
}
