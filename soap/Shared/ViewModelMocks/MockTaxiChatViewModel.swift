//
//  MockTaxiChatViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI
import Observation

@Observable
class MockTaxiChatViewModel: TaxiChatViewModelProtocol {
  // MARK: - ViewModel Properties
  var state: TaxiChatViewModel.ViewState = .loading
  var groupedChats: [TaxiChatGroup] = []
  var taxiUser: TaxiUser?
  var fetchedDateSet: Set<Date> = []
  var room: TaxiRoom = TaxiRoom.mock

  // MARK: - Computed Properties
  var isLeaveRoomAvailable: Bool = true
  var isCommitSettlementAvailable: Bool = false
  var isCommitPaymentAvailable: Bool = false

  // MARK: - Functions
  func fetchChats(before date: Date) async {
    // Mock implementation - no actual fetching
  }
  
  func sendChat(_ message: String, type: TaxiChat.ChatType) {
    // Mock implementation - no actual sending
  }
  
  func leaveRoom() async throws {
    // Mock implementation - no actual leaving
  }
  
  func commitSettlement() {
    // Mock implementation - no actual settlement
  }
  
  func commitPayment() {
    // Mock implementation - no actual payment
  }
} 
