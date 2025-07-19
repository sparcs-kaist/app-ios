//
//  UserStorage.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

actor UserStorage: UserStorageProtocol {
  private var taxiUser: TaxiUser?

  func setTaxiUser(_ user: TaxiUser?) {
    self.taxiUser = user
  }

  func getTaxiUser() -> TaxiUser? {
    return taxiUser
  }
}
