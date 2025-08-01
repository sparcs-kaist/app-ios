//
//  TaxiRoomStatusIndicator.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI

struct TaxiRoomStatusIndicator: View {
  let settlementType: TaxiParticipant.SettlementType
  let settlementCount: Int
  let participantsCount: Int

  var body: some View {
    Group {
      switch settlementType {
      case .notDeparted:
        Text("Settlement Required")
      case .requestedSettlement:
        if settlementCount >= participantsCount {
          Text("Settlement Completed")
        } else {
          Text("Settlement Requested")
        }
      case .paymentRequired:
        Text("Payment Required")
      case .paymentSent:
        Text("Payment Settled")
      }
    }
    .font(.footnote)
    .foregroundStyle(accentColor)
    .padding(4)
    .padding(.horizontal, 4)
    .background(accentColor.opacity(0.1))
    .clipShape(.capsule)
  }

  private var accentColor: Color {
    switch settlementType {
    case .notDeparted:
        .orange
    case .requestedSettlement:
      if settlementCount >= participantsCount {
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
