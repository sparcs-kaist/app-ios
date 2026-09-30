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
  public let degree: String?
  public let majorDepartments: [DepartmentDTO]
  public let interestedDepartments: [DepartmentDTO]

  enum CodingKeys: String, CodingKey {
    case id, name, studentNumber, degree, majorDepartments, interestedDepartments
    // The OTL API returns the address under `mail`.
    case email = "mail"
  }
}


public extension OTLUserDTO {
  func toModel() -> OTLUser {
    OTLUser(
      id: id,
      name: name,
      email: mail ?? "",
      studentNumber: studentNumber ?? 0,
      degree: degree ?? "",
      majorDepartments: majorDepartments.compactMap { $0.toModel () },
      interestedDepartments: interestedDepartments.compactMap { $0.toModel() }
    )
  }
}
