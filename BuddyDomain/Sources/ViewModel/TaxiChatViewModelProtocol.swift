//
//  TaxiChatViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import Observation
import UIKit

@MainActor
public protocol TaxiChatViewModelProtocol: Observable {
  var state: TaxiChatViewState { get }
  var renderItems: [ChatRenderItem] { get }
  var taxiUser: TaxiUser? { get }
  var room: TaxiRoom { get }
  var isUploading: Bool { get }

  var scrollToBottomTrigger: Int { get }

  var alertState: AlertState? { get set }
  var isAlertPresented: Bool { get set }

  var isLeaveRoomAvailable: Bool { get }
  var isCommitSettlementAvailable: Bool { get }
  var isCommitPaymentAvailable: Bool { get }
  var isArrivalToggleEnabled: Bool { get }
  var isArrived: Bool { get set }
  var hasCarrier: Bool { get set }
  var arrivedCount: Int { get }
  var account: String? { get }
  var topChatID: String? { get }

  func setup() async

  func loadMoreChats() async
  func fetchInitialChats() async
  func sendChat(_ message: String, type: TaxiChat.ChatType)
  func leaveRoom() async throws
  func commitSettlement()
  func commitPayment()
  func updateArrival(isArrived: Bool)
  func updateCarrier(hasCarrier: Bool)
  func sendImage(_ image: UIImage) async throws
}
