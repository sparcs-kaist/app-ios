//
//  UserStorageProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol UserStorageProtocol: Actor {
  func setAraUser(_ user: AraUser?)
  func getAraUser() -> AraUser?

  func setTaxiUser(_ user: TaxiUser?)
  func getTaxiUser() -> TaxiUser?

  func setFeedUser(_ user: FeedUser?)
  func getFeedUser() -> FeedUser?

  func setOTLUser(_ user: OTLUser?)
  func getOTLUser() -> OTLUser?
}
