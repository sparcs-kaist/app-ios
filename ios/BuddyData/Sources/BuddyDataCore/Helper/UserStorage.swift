//
//  UserStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation
import BuddyDomain

public actor UserStorage: UserStorageProtocol {
  // MARK: - Ara User
  private var araUser: AraUser?

  public func setAraUser(_ user: AraUser?) {
    self.araUser = user
  }

  public func getAraUser() -> AraUser? {
    return araUser
  }

  // MARK: - Taxi User
  private var taxiUser: TaxiUser?

  public func setTaxiUser(_ user: TaxiUser?) {
    self.taxiUser = user
  }
  
  public func getTaxiUser() -> TaxiUser? {
    return taxiUser
  }

  // MARK: - Feed User
  private var feedUser: FeedUser?

  public func setFeedUser(_ user: FeedUser?) {
    self.feedUser = user
  }

  public func getFeedUser() -> FeedUser? {
    return feedUser
  }

  // MARK: - OTL User
  private var otlUser: OTLUser?

  public func setOTLUser(_ user: OTLUser?) {
    self.otlUser = user
  }

  public func getOTLUser() -> OTLUser? {
    return otlUser
  }

  public init(
    araUser: AraUser? = nil,
    taxiUser: TaxiUser? = nil,
    feedUser: FeedUser? = nil,
    otlUser: OTLUser? = nil
  ) {
    self.araUser = araUser
    self.taxiUser = taxiUser
    self.feedUser = feedUser
    self.otlUser = otlUser
  }
}
