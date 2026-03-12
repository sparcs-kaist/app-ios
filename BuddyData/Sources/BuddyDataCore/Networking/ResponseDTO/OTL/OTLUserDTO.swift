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
  public let email: String
  public let studentID: String
  public let firstName: String
  public let lastName: String

  enum CodingKeys: String, CodingKey {
    case id
    case email
    case studentID = "student_id"
    case firstName
    case lastName
  }
}


public extension OTLUserDTO {
  func toModel() -> OTLUser {
    OTLUser(
      id: id,
      email: email,
      studentID: studentID,
      firstName: firstName,
      lastName: lastName
    )
  }
}
