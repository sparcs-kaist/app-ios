//
//  NextClassResult.swift
//  soap
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import AppIntents

struct NextClassResult: TransientAppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(
    name: "Next Class"
  )

  @Property
  var title: String

  @Property
  var location: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title),
      subtitle: LocalizedStringResource(stringLiteral: location),
      image: .init(systemName: "calendar.badge.clock")
    )
  }

  init() {

  }

  init(title: String, location: String) {
    self.title = title
    self.location = location
  }
}
