//
//  OLEVTimetable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation

/// The OLEV campus shuttle: a one-way loop through fixed stops, departing the first stop at set times on
/// weekdays (https://www.kaist.ac.kr/kr/html/kaist/01140203.html).
public struct OLEVTimetable: Hashable, Sendable {
  public struct Stop: Hashable, Sendable {
    public let placeID: String
    /// Minutes after the bus leaves the first stop.
    public let offset: Int
    /// The road from this stop to the next one (the last stop's leads back to the first); empty when
    /// unknown.
    public let path: [PathPoint]

    public init(placeID: String, offset: Int, path: [PathPoint] = []) {
      self.placeID = placeID
      self.offset = offset
      self.path = path
    }
  }

  public struct PathPoint: Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
      self.latitude = latitude
      self.longitude = longitude
    }
  }

  /// Departures from the first stop, in minutes since midnight.
  public let departures: [Int]
  public let stops: [Stop]
  /// `Calendar` weekdays the shuttle runs on.
  public let serviceDays: Set<Int>

  public init(departures: [Int], stops: [Stop], serviceDays: Set<Int> = [2, 3, 4, 5, 6]) {
    self.departures = departures
    self.stops = stops
    self.serviceDays = serviceDays
  }

  public func contains(placeID: String) -> Bool {
    stops.contains { $0.placeID == placeID }
  }

  /// The bus that just left `placeID`, the next one and the one after, as the stop sign shows them.
  public func arrivals(at placeID: String, around date: Date, calendar: Calendar = .current) -> OLEVArrivals {
    guard let stop = stops.first(where: { $0.placeID == placeID }) else {
      return OLEVArrivals(previous: nil, upcoming: [])
    }

    var times: [Date] = []
    let startOfToday = calendar.startOfDay(for: date)
    // Today and the next week, so "no more buses" rolls over to the next service day.
    for dayOffset in 0...7 {
      guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday),
            serviceDays.contains(calendar.component(.weekday, from: day)) else { continue }
      times += departures.map { day.addingTimeInterval(TimeInterval(($0 + stop.offset) * 60)) }
      if times.filter({ $0 > date }).count >= 2 { break }
    }

    return OLEVArrivals(
      previous: times.last { $0 <= date && calendar.isDate($0, inSameDayAs: date) },
      upcoming: Array(times.filter { $0 > date }.prefix(2))
    )
  }

  /// Where each running bus is right now, as a fraction between two consecutive stops.
  public func buses(at date: Date, calendar: Calendar = .current) -> [OLEVBusPosition] {
    guard serviceDays.contains(calendar.component(.weekday, from: date)),
          let lastOffset = stops.last?.offset else { return [] }
    let minute = Double(calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date))
      + Double(calendar.component(.second, from: date)) / 60

    return departures.compactMap { departure in
      let elapsed = minute - Double(departure)
      guard elapsed >= 0, elapsed < Double(lastOffset) else { return nil }
      guard let index = stops.lastIndex(where: { Double($0.offset) <= elapsed }),
            index + 1 < stops.count else { return nil }
      let from = stops[index], to = stops[index + 1]
      let fraction = (elapsed - Double(from.offset)) / Double(to.offset - from.offset)
      return OLEVBusPosition(departure: departure, fromStopIndex: index, toStopIndex: index + 1, fraction: fraction)
    }
  }
}

public struct OLEVArrivals: Hashable, Sendable {
  public let previous: Date?
  public let upcoming: [Date]

  public init(previous: Date?, upcoming: [Date]) {
    self.previous = previous
    self.upcoming = upcoming
  }

  public var next: Date? { upcoming.first }
}

public struct OLEVBusPosition: Identifiable, Hashable, Sendable {
  public var id: Int { departure }
  public let departure: Int
  public let fromStopIndex: Int
  public let toStopIndex: Int
  public let fraction: Double
}
