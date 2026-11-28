//
//  OTLUserDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

public struct OTLUserDTO: Codable {
  public let id: Int
  public let name: String
  // The server sends the address as `mail`, and leaves these empty for accounts without them.
  public let mail: String?
  public let studentNumber: Int?
  /// Nullable on the server (`string | null`); a non-optional type here made
  /// the whole user fail to decode for accounts without a degree.
  public let degree: String?
  public let majorDepartments: [DepartmentDTO]?
  public let interestedDepartments: [DepartmentDTO]?
}


public extension OTLUserDTO {
  func toModel() -> OTLUser {
    OTLUser(
      id: id,
      name: name,
      email: mail ?? "",
      studentNumber: studentNumber ?? 0,
      degree: degree,
      majorDepartments: (majorDepartments ?? []).compactMap { $0.toModel() },
      interestedDepartments: (interestedDepartments ?? []).compactMap { $0.toModel() }
    )
  }
}
