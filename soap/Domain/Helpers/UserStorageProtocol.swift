//
//  UserStorageProtocol.swift
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
