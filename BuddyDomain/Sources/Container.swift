//
//  Container.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 27/01/2026.
//

import Foundation
import Factory

extension Container {

  // MARK: - Repositories

  // MARK:  Taxi
  public var taxiRoomRepository: Factory<TaxiRoomRepositoryProtocol?> {
    promised()
  }

  public var taxiUserRepository: Factory<TaxiUserRepositoryProtocol?> {
    promised()
  }

  public var taxiChatRepository: Factory<TaxiChatRepositoryProtocol?> {
    promised()
  }

  public var taxiReportRepository: Factory<TaxiReportRepositoryProtocol?> {
    promised()
  }

  // MARK: Ara
  public var araUserRepository: Factory<AraUserRepositoryProtocol?> {
    promised()
  }

  public var araBoardRepository: Factory<AraBoardRepositoryProtocol?> {
    promised()
  }

  public var araCommentRepository: Factory<AraCommentRepositoryProtocol?> {
    promised()
  }
}
