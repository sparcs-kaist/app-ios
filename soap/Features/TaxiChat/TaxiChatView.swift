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
      ScrollView {
        LazyVStack {
          Text("hello")
        }
      }
      .navigationTitle(Text(room.title))
      .navigationSubtitle(Text("\(room.source.title.localized()) → \(room.destination.title.localized())"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu("More", systemImage: "ellipsis") {

          }
        }
      }
    }
  }
}

#Preview {
  TaxiChatView(room: TaxiRoom.mock)
}
