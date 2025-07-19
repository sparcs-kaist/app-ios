//
//  UserStorageProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

protocol UserStorageProtocol: Actor {
  func setTaxiUser(_ user: TaxiUser?)
  func getTaxiUser() -> TaxiUser?
}
