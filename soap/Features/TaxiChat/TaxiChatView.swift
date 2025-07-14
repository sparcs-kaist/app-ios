//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI

struct TaxiChatView: View {
  let room: TaxiRoom

  var body: some View {
    NavigationStack {
      Text("hello")
        .navigationTitle(Text(room.title))
        .navigationSubtitle(Text(
          Text(room.source.title.localized()) + Text(room.destination.title.localized())
        )
    }
  }
}

#Preview {
  TaxiChatView(room: TaxiRoom.mock)
}
