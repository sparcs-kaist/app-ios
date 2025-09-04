//
//  UserStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

actor UserStorage: UserStorageProtocol {
  private var araUser: AraUser?
  private var taxiUser: TaxiUser?

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
}
