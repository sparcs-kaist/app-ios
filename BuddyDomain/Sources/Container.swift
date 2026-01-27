//
//  Container.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 27/01/2026.
//

import Foundation
import Factory

extension Container {
  public var taxiRoomRepository: Factory<TaxiRoomRepositoryProtocol?> {
    promised()
  }
}
