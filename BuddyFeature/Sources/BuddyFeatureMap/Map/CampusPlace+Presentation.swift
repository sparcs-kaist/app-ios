//
//  CampusPlace+Presentation.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import MapKit
import BuddyDomain

extension CampusPlace {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  private static var prefersKorean: Bool {
    Locale.preferredLanguages.first?.hasPrefix("ko") ?? false
  }

  /// The name in the user's language: Korean users know places by their Korean names.
  var displayName: String {
    let localizedName = Self.prefersKorean ? nameKo : name
    let suffix = "정류장"
    guard category == .olevStop, localizedName.hasSuffix(suffix) else { return localizedName }
    return String(localizedName.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var displayFloor: String? {
    guard let floor = floor?.trimmingCharacters(in: .whitespacesAndNewlines), !floor.isEmpty else {
      return nil
    }
    for code in [buildingCode, code].compactMap({ $0 }) {
      let prefix = "\(code) "
      if floor.hasPrefix(prefix) {
        return String(floor.dropFirst(prefix.count))
      }
    }
    return floor
  }

  var marker: some MapContent {
    Marker(displayName, systemImage: category.symbolName, coordinate: coordinate)
  }

  /// What the share sheet sends: the name and an Apple Maps link to the spot.
  var shareText: String {
    "\(displayName) — https://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
  }

  /// "Cafeteria · N11" — the category, then where it is.
  var subtitle: String {
    [category.title, code ?? buildingCode].compactMap { $0 }.joined(separator: " · ")
  }
}

extension CampusPlaceCategory {
  var title: String {
    switch self {
    case .building: String(localized: "Building", bundle: .module)
    case .academicBuilding: String(localized: "Academic Building", bundle: .module)
    case .parking: String(localized: "Parking", bundle: .module)
    case .cafe: String(localized: "Café", bundle: .module)
    case .cafeteria: String(localized: "Cafeteria", bundle: .module)
    case .restaurant: String(localized: "Restaurant", bundle: .module)
    case .dormitory: String(localized: "Residence Hall", bundle: .module)
    case .library: String(localized: "Library", bundle: .module)
    case .sportsField: String(localized: "Sports", bundle: .module)
    case .hospital: String(localized: "Clinic", bundle: .module)
    case .olevStop: String(localized: "OLEV Stop", bundle: .module)
    case .store: String(localized: "Store", bundle: .module)
    case .gate: String(localized: "Gate", bundle: .module)
    case .theater: String(localized: "Hall", bundle: .module)
    case .postOffice: String(localized: "Post Office", bundle: .module)
    case .printShop: String(localized: "Print Shop", bundle: .module)
    }
  }

  var symbolName: String {
    switch self {
    case .building: "building.2.fill"
    case .academicBuilding: "graduationcap.fill"
    case .parking: "parkingsign"
    case .cafe: "cup.and.saucer.fill"
    case .cafeteria: "fork.knife"
    case .restaurant: "takeoutbag.and.cup.and.straw.fill"
    case .dormitory: "bed.double.fill"
    case .library: "books.vertical.fill"
    case .sportsField: "figure.run"
    case .hospital: "cross.fill"
    case .olevStop: "bus.fill"
    case .store: "basket.fill"
    case .gate: "signpost.right.fill"
    case .theater: "theatermasks.fill"
    case .postOffice: "envelope.fill"
    case .printShop: "printer.fill"
    }
  }

  /// Follows Apple Maps' palette: orange for food, brown for coffee, blue for transit.
  var tint: Color {
    switch self {
    case .building, .gate: .gray
    case .academicBuilding: .indigo
    case .parking: .blue
    case .cafe: .brown
    case .cafeteria, .restaurant: .orange
    case .dormitory: .purple
    case .library: .cyan
    case .sportsField: .green
    case .hospital: .red
    case .olevStop: .blue
    case .store: .yellow
    case .theater: .pink
    case .postOffice: .red
    case .printShop: .teal
    }
  }
}

/// The groups offered as filter chips; the backend's categories are too fine-grained to list.
enum CampusPlaceFilter: String, CaseIterable, Identifiable {
  /// Whatever is closest, of any kind.
  case nearby
  case dining
  case cafes
  case olev
  case stores
  case study
  case housing
  case health

  var id: String { rawValue }

  var title: String {
    switch self {
    case .nearby: String(localized: "Nearby", bundle: .module)
    case .dining: String(localized: "Dining", bundle: .module)
    case .cafes: String(localized: "Cafés", bundle: .module)
    case .olev: String(localized: "OLEV", bundle: .module)
    case .stores: String(localized: "Stores", bundle: .module)
    case .study: String(localized: "Study", bundle: .module)
    case .housing: String(localized: "Housing", bundle: .module)
    case .health: String(localized: "Health & Sports", bundle: .module)
    }
  }

  var symbolName: String {
    switch self {
    case .nearby: "location.fill"
    case .dining: "fork.knife"
    case .cafes: "cup.and.saucer.fill"
    case .olev: "bus.fill"
    case .stores: "basket.fill"
    case .study: "books.vertical.fill"
    case .housing: "bed.double.fill"
    case .health: "figure.run"
    }
  }

  var tint: Color {
    switch self {
    case .nearby: .blue
    case .dining: .orange
    case .cafes: .brown
    case .olev: .blue
    case .stores: .yellow
    case .study: .cyan
    case .housing: .purple
    case .health: .green
    }
  }

  var categories: Set<CampusPlaceCategory> {
    switch self {
    case .nearby: Set(CampusPlaceCategory.allCases)
    case .dining: [.cafeteria, .restaurant]
    case .cafes: [.cafe]
    case .olev: [.olevStop]
    case .stores: [.store, .printShop, .postOffice]
    case .study: [.library, .academicBuilding, .building, .theater, .gate]
    case .housing: [.dormitory]
    case .health: [.hospital, .sportsField]
    }
  }
}

extension MealKind {
  var title: String {
    switch self {
    case .breakfast: String(localized: "Breakfast", bundle: .module)
    case .lunch: String(localized: "Lunch", bundle: .module)
    case .dinner: String(localized: "Dinner", bundle: .module)
    }
  }

  var symbolName: String {
    switch self {
    case .breakfast: "sunrise.fill"
    case .lunch: "sun.max.fill"
    case .dinner: "moon.stars.fill"
    }
  }

  /// The meal worth showing first at this time of day.
  static func current(at date: Date = .now, calendar: Calendar = .current) -> MealKind {
    switch calendar.component(.hour, from: date) {
    case ..<10: .breakfast
    case ..<15: .lunch
    default: .dinner
    }
  }
}

// MARK: - Formatting

extension Int {
  /// Minutes since midnight as a time of day, honouring the system 12/24-hour setting.
  var minutesAsTimeText: String {
    let date = Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(self * 60))
    return date.formatted(date: .omitted, time: .shortened)
  }

  var wonText: String {
    formatted(.currency(code: "KRW").presentation(.narrow))
  }
}

extension CLLocationDistance {
  /// "120 m" or "1.2 km".
  var distanceText: String {
    Measurement(value: self, unit: UnitLength.meters)
      .formatted(.measurement(width: .abbreviated, usage: .road, numberFormatStyle: .number.precision(.significantDigits(2))))
  }

  /// Walking time at a relaxed 75 m a minute.
  var walkingMinutes: Int {
    Swift.max(1, Int((self / 75).rounded()))
  }
}

extension OpeningStatus {
  var title: String {
    switch self {
    case .alwaysOpen: String(localized: "Open 24 hours", bundle: .module)
    case .open: String(localized: "Open", bundle: .module)
    case .closingSoon: String(localized: "Closes soon", bundle: .module)
    case .closed: String(localized: "Closed", bundle: .module)
    }
  }

  var detail: String? {
    switch self {
    case .alwaysOpen:
      return nil
    case .open(let closes), .closingSoon(let closes):
      return String(localized: "Closes \(closes.minutesAsTimeText)", bundle: .module)
    case .closed(let opens?, 0):
      return String(localized: "Opens \(opens.minutesAsTimeText)", bundle: .module)
    case .closed(let opens?, 1):
      return String(localized: "Opens tomorrow \(opens.minutesAsTimeText)", bundle: .module)
    case .closed(let opens?, let dayOffset):
      let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
      return String(localized: "Opens \(day.formatted(.dateTime.weekday(.abbreviated))) \(opens.minutesAsTimeText)", bundle: .module)
    case .closed(nil, _):
      return nil
    }
  }

  var tint: Color {
    switch self {
    case .alwaysOpen, .open: .green
    case .closingSoon: .orange
    case .closed: .red
    }
  }
}
