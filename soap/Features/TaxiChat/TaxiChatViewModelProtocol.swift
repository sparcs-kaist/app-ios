//
//  TaxiChatViewModelProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import Foundation
import UIKit

@MainActor
protocol TaxiChatViewModelProtocol: Observable {
  // MARK: - ViewModel Properties
  var state: TaxiChatViewModel.ViewState { get }
  var groupedChats: [TaxiChatGroup] { get }
  var taxiUser: TaxiUser? { get }
  var fetchedDateSet: Set<Date> { get set }
  var room: TaxiRoom { get }
  var isUploading: Bool { get }

  // MARK: - Computed Properties
  var isLeaveRoomAvailable: Bool { get }
  var isCommitSettlementAvailable: Bool { get }
  var isCommitPaymentAvailable: Bool { get }

  // MARK: - Functions
  func fetchChats(before date: Date) async
  func sendChat(_ message: String, type: TaxiChat.ChatType)
  func leaveRoom() async throws
  func commitSettlement()
  func commitPayment()
  func sendImage(_ image: UIImage) async throws
}
