//
//  UserStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

protocol UserStorageProtocol: Actor {
  func setAraUser(_ user: AraUser?)
  func setTaxiUser(_ user: TaxiUser?)
  func getAraUser() -> AraUser?
  func getTaxiUser() -> TaxiUser?

  func setFeedUser(_ user: FeedUser?)
  func getFeedUser() -> FeedUser?
}


actor UserStorage: UserStorageProtocol {
  private var araUser: AraUser?
  private var taxiUser: TaxiUser?
  private var feedUser: FeedUser?

  func setAraUser(_ user: AraUser?) {
    self.araUser = user
  }
  
  func setTaxiUser(_ user: TaxiUser?) {
    self.taxiUser = user
  }

  func getAraUser() -> AraUser? {
    return araUser
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
