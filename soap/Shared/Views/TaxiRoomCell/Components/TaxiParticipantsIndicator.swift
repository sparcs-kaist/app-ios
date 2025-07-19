//
//  TaxiParticipantsIndicator.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI

struct TaxiParticipantsIndicator: View {
  let participants: Int
  let capacity: Int

  var body: some View {
    HStack(spacing: 4) {
      Text("\(participants)/\(capacity)")
      Image(systemName: "person.2")
    }
    .font(.footnote)
    .foregroundStyle(accentColor)
    .padding(4)
    .padding(.horizontal, 4)
    .background(accentColor.opacity(0.1))
    .clipShape(.capsule)
  }

  private var accentColor: Color {
    switch capacity - participants {
    case 0:
      .red
    case 1:
      .orange
    default:
      .green
    }
  }
}


#Preview(traits: .sizeThatFitsLayout) {
  TaxiParticipantsIndicator(participants: 1, capacity: 4)
  TaxiParticipantsIndicator(participants: 2, capacity: 4)
  TaxiParticipantsIndicator(participants: 3, capacity: 4)
  TaxiParticipantsIndicator(participants: 4, capacity: 4)
}
