//
//  UserStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

actor UserStorage: UserStorageProtocol {
  private var taxiUser: TaxiUser?
  private var feedUser: FeedUser?

  func setTaxiUser(_ user: TaxiUser?) {
    self.taxiUser = user
  }

  func getTaxiUser() -> TaxiUser? {
    return taxiUser
  }

  func setFeedUser(_ user: FeedUser?) {
    self.feedUser = user
  }

  func getFeedUser() -> FeedUser? {
    return feedUser
  }
}
