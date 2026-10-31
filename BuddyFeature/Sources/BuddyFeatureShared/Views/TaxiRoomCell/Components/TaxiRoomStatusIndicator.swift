//
//  TaxiRoomStatusIndicator.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import Foundation
import SwiftUI
import BuddyDomain

/// Where your settlement for a departed ride stands, as a tinted capsule with a symbol.
struct TaxiRoomStatusIndicator: View {
  let settlementType: TaxiParticipant.SettlementType
  let settlementCount: Int
  let participantsCount: Int
  /// A fixed height, to match what the capsule sits level with; its own otherwise.
  var height: CGFloat? = nil

  var body: some View {
    HStack(spacing: 3) {
      Image(systemName: symbol)
      title
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(accentColor)
    .lineLimit(1)
    .padding(.horizontal, 7)
    .padding(.vertical, height == nil ? 4 : 0)
    .frame(height: height)
    .background(accentColor.opacity(0.12), in: .capsule)
  }

  private var isSettlementCompleted: Bool {
    settlementCount >= participantsCount
  }

  private var symbol: String {
    switch settlementType {
    case .notDeparted: "exclamationmark.circle.fill"
    case .requestedSettlement: isSettlementCompleted ? "checkmark.circle.fill" : "clock.fill"
    case .paymentRequired: "wonsign.circle.fill"
    case .paymentSent: "checkmark.circle.fill"
    }
  }

  private var title: some View {
    Group {
      switch settlementType {
      case .notDeparted:
        Text("Settlement Required", bundle: .module)
      case .requestedSettlement:
        if isSettlementCompleted {
          Text("Settlement Completed", bundle: .module)
        } else {
          Text("Settlement Requested", bundle: .module)
        }
      case .paymentRequired:
        Text("Payment Required", bundle: .module)
      case .paymentSent:
        Text("Payment Settled", bundle: .module)
      }
    }
  }

  private var accentColor: Color {
    switch settlementType {
    case .notDeparted:
        .orange
    case .requestedSettlement:
      if isSettlementCompleted {
        .green
      } else {
        .blue
      }
    case .paymentRequired:
        .red
    case .paymentSent:
        .green
    }
  }
}


#Preview(traits: .sizeThatFitsLayout) {
  TaxiRoomStatusIndicator(settlementType: .notDeparted, settlementCount: 0, participantsCount: 4)
  TaxiRoomStatusIndicator(settlementType: .paymentRequired, settlementCount: 0, participantsCount: 4)
  TaxiRoomStatusIndicator(settlementType: .paymentSent, settlementCount: 0, participantsCount: 4)
  TaxiRoomStatusIndicator(settlementType: .requestedSettlement, settlementCount: 4, participantsCount: 4)
  TaxiRoomStatusIndicator(settlementType: .requestedSettlement, settlementCount: 0, participantsCount: 4)
}
