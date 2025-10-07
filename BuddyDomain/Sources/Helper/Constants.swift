//
//  Constants.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import Foundation

public func dateOnSameDay(minutes: Int, date: Date, calendar: Calendar) -> Date? {
  let h = minutes / 60
  let m = minutes % 60
  var comps = calendar.dateComponents([.year, .month, .day], from: date)
  comps.hour = h
  comps.minute = m
  comps.second = 0
  return calendar.date(from: comps)
}
