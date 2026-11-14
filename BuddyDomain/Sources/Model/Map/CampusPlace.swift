//
//  CampusPlace.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation

/// A point of interest on the KAIST campus map: a building, a facility inside one, or an OLEV stop.
///
/// Shaped after `LocationDetailResponse` in sparcsapp-back (`/v1/locations/{id}`), with the
/// presentation fields the map needs (summary, photos, phone) that the backend keeps in `notes`.
public struct CampusPlace: Identifiable, Hashable, Sendable {
  public let id: String
  /// Campus map code such as `E11` or `N11`. Facilities inside a building have none.
  public let code: String?
  public let name: String
  public let nameKo: String
  public let category: CampusPlaceCategory
  public let latitude: Double
  public let longitude: Double
  /// Code of the building a facility sits in, e.g. `N11` for the restaurants in the cafeteria.
  public let buildingCode: String?
  public let keywords: [String]
  public let summary: String?
  public let openingHours: OpeningHours?
  public let hoursNote: String?
  public let phoneNumber: String?
  public let floor: String?
  public let photos: [PlacePhoto]

  public init(
    id: String,
    code: String? = nil,
    name: String,
    nameKo: String,
    category: CampusPlaceCategory,
    latitude: Double,
    longitude: Double,
    buildingCode: String? = nil,
    keywords: [String] = [],
    summary: String? = nil,
    openingHours: OpeningHours? = nil,
    hoursNote: String? = nil,
    phoneNumber: String? = nil,
    floor: String? = nil,
    photos: [PlacePhoto] = []
  ) {
    self.id = id
    self.code = code
    self.name = name
    self.nameKo = nameKo
    self.category = category
    self.latitude = latitude
    self.longitude = longitude
    self.buildingCode = buildingCode
    self.keywords = keywords
    self.summary = summary
    self.openingHours = openingHours
    self.hoursNote = hoursNote
    self.phoneNumber = phoneNumber
    self.floor = floor
    self.photos = photos
  }
}

public enum CampusPlaceCategory: String, CaseIterable, Hashable, Sendable {
  case building
  case academicBuilding
  case parking
  case cafe
  case cafeteria
  case restaurant
  case dormitory
  case library
  case sportsField
  case hospital
  case olevStop
  case store
  case gate
  case theater
  case postOffice
  case printShop
}

/// A photo of a place. Mock places carry no URL; the UI draws a placeholder tinted by `hue`.
public struct PlacePhoto: Identifiable, Hashable, Sendable {
  public let id: String
  public let url: URL?
  public let caption: String?
  /// 0...1, used to vary placeholders until real photos exist.
  public let hue: Double

  public init(id: String, url: URL? = nil, caption: String? = nil, hue: Double) {
    self.id = id
    self.url = url
    self.caption = caption
    self.hue = hue
  }
}
