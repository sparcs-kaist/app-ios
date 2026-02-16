//
//  TaxiChatViewModelProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import Foundation
import UIKit
import BuddyDomain

@MainActor
protocol TaxiChatViewModelProtocol: Observable {
  // MARK: - ViewModel Properties
  var state: TaxiChatViewModel.ViewState { get }
  var groupedChats: [TaxiChatGroup] { get }
  var renderItems: [ChatRenderItem] { get }
  var taxiUser: TaxiUser? { get }
  var room: TaxiRoom { get }
  var isUploading: Bool { get }

  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }

  // MARK: - Computed Properties
  var isLeaveRoomAvailable: Bool { get }
  var isCommitSettlementAvailable: Bool { get }
  var isCommitPaymentAvailable: Bool { get }
  var account: String? { get }
  var topChatID: String? { get }

  // MARK: - Functions
  func setup() async

  func loadMoreChats() async
  func fetchInitialChats() async
  func sendChat(_ message: String, type: TaxiChat.ChatType)
  func leaveRoom() async throws
  func commitSettlement()
  func commitPayment()
  func sendImage(_ image: UIImage) async throws
  func hasBadge(authorID: String?) -> Bool
}
