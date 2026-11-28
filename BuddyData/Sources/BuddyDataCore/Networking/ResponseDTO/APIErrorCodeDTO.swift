//
//  APIErrorCodeDTO.swift
//  BuddyData
//

import Foundation

/// The machine-readable `code` some otlplus-server errors carry, such as
/// `SELF_FRIENDSHIP`. Absent from most of them.
struct APIErrorCodeDTO: Decodable {
  let code: String?
}
