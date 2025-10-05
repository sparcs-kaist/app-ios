//
//  UserStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation
import BuddyDomain

actor UserStorage: UserStorageProtocol {
  // MARK: - Ara User
  private var araUser: AraUser?

  func setAraUser(_ user: AraUser?) {
    self.araUser = user
  }

  func getAraUser() -> AraUser? {
    return araUser
  }

  // MARK: - Taxi User
  private var taxiUser: TaxiUser?

  func setTaxiUser(_ user: TaxiUser?) {
    self.taxiUser = user
  }
  
  func getTaxiUser() -> TaxiUser? {
    return taxiUser
  }

  // MARK: - Feed User
  private var feedUser: FeedUser?

  func setFeedUser(_ user: FeedUser?) {
    self.feedUser = user
  }

  func getFeedUser() -> FeedUser? {
    return feedUser
  }

  // MARK: - OTL User
  private var otlUser: OTLUser?

  func setOTLUser(_ user: OTLUser?) {
    self.otlUser = user
  }

  func getOTLUser() -> OTLUser? {
    return otlUser
  }
}
