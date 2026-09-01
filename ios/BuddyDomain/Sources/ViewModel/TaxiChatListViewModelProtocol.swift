//
//  TaxiChatListViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

@MainActor
public protocol TaxiChatListViewModelProtocol: Observable {
  // MARK: - ViewModel Properties
  var state: TaxiChatListViewState { get }
  var taxiUser: TaxiUser? { get }

  // MARK: - Functions
  func fetchData() async
}
