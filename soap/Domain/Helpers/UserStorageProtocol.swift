//
//  UserStorageProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation

protocol UserStorageProtocol: Actor {
  func setAraUser(_ user: AraMe?)
  func setTaxiUser(_ user: TaxiUser?)
  func getAraUser() -> AraMe?
  func getTaxiUser() -> TaxiUser?
}
