//
//  ChatDaySeperator.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import SwiftUI

struct ChatDaySeperator: View {
  let date: Date

  var body: some View {
    Text(date.formattedDate)
      .fontWeight(.medium)
      .font(.footnote)
  }
}

#Preview {
  ChatDaySeperator(date: Date())
}
