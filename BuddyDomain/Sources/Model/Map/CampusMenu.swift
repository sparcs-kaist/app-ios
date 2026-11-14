//
//  CampusMenu.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation

public enum MealKind: String, CaseIterable, Identifiable, Hashable, Sendable {
  case breakfast
  case lunch
  case dinner

  public var id: String { rawValue }
}

/// A day's menu at a campus cafeteria (학식), split into meals and then courses (코너).
public struct CafeteriaMenu: Hashable, Sendable {
  public let placeID: String
  public let date: Date
  public let meals: [CafeteriaMeal]

  public init(placeID: String, date: Date, meals: [CafeteriaMeal]) {
    self.placeID = placeID
    self.date = date
    self.meals = meals
  }

  public func meal(_ kind: MealKind) -> CafeteriaMeal? {
    meals.first { $0.kind == kind }
  }
}

public struct CafeteriaMeal: Identifiable, Hashable, Sendable {
  public var id: MealKind { kind }
  public let kind: MealKind
  public let serving: OpeningHours.Interval
  public let courses: [CafeteriaCourse]

  public init(kind: MealKind, serving: OpeningHours.Interval, courses: [CafeteriaCourse]) {
    self.kind = kind
    self.serving = serving
    self.courses = courses
  }
}

public struct CafeteriaCourse: Identifiable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let dishes: [String]
  /// Price in won.
  public let price: Int
  public let calories: Int?

  public init(id: String, name: String, dishes: [String], price: Int, calories: Int? = nil) {
    self.id = id
    self.name = name
    self.dishes = dishes
    self.price = price
    self.calories = calories
  }
}

/// A restaurant's standing menu.
public struct RestaurantMenu: Hashable, Sendable {
  public let placeID: String
  public let sections: [RestaurantMenuSection]

  public init(placeID: String, sections: [RestaurantMenuSection]) {
    self.placeID = placeID
    self.sections = sections
  }

  public var popularItems: [RestaurantMenuItem] {
    sections.flatMap(\.items).filter(\.isPopular)
  }
}

public struct RestaurantMenuSection: Identifiable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let items: [RestaurantMenuItem]

  public init(id: String, title: String, items: [RestaurantMenuItem]) {
    self.id = id
    self.title = title
    self.items = items
  }
}

public struct RestaurantMenuItem: Identifiable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let detail: String?
  /// Price in won.
  public let price: Int
  public let isPopular: Bool

  public init(id: String, name: String, detail: String? = nil, price: Int, isPopular: Bool = false) {
    self.id = id
    self.name = name
    self.detail = detail
    self.price = price
    self.isPopular = isPopular
  }
}
