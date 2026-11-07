//
//  TaxiFavoriteRouteDTO.swift
//  BuddyData
//

import Foundation
import BuddyDomain

struct TaxiFavoriteRouteDTO: Decodable {
  let id: String
  let from: LocationReference?
  let to: LocationReference?
  let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case from
    case to
    case createdAt
  }

  /// A place the route runs between: only its ID when the route was just created, the place
  /// itself when the routes are listed, and `null` once the place has been removed.
  struct LocationReference: Decodable {
    let id: String

    private enum CodingKeys: String, CodingKey {
      case id = "_id"
    }

    init(from decoder: Decoder) throws {
      if let id = try? decoder.singleValueContainer().decode(String.self) {
        self.id = id
      } else {
        self.id = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .id)
      }
    }
  }
}

extension TaxiFavoriteRouteDTO {
  /// `nil` for a route to or from a place that no longer exists.
  func toModel() -> TaxiFavoriteRoute? {
    guard let from, let to else { return nil }
    return TaxiFavoriteRoute(
      id: id,
      sourceID: from.id,
      destinationID: to.id,
      createdAt: createdAt?.toDate() ?? Date()
    )
  }
}
