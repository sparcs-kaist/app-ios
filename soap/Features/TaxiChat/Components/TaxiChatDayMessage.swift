//
//  TaxiChatDayMessage.swift
//  soap
//
//  Created by Soongyu Kwon on 18/07/2025.
//

import SwiftUI

struct TaxiChatDayMessage: View {
  let date: Date

  var body: some View {
    Text(date.formattedDate)
      .fontWeight(.medium)
      .font(.footnote)
  }
}

#Preview {
  TaxiChatDayMessage(date: Date())
}
