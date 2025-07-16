//
//  TaxiChatView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI

struct TaxiChatView: View {
  let room: TaxiRoom

  @State private var text: String = ""

  var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        ScrollView {
          LazyVStack {
            ForEach(0..<100) { _ in
              Text("Hello")
            }
          }
        }

        HStack {
          Button("More", systemImage: "plus") { }
            .labelStyle(.iconOnly)
            .padding()
            .glassEffect(.regular.interactive(), in: .circle)

          HStack {
            TextField("Type a message...", text: $text)
              .padding(.leading, 4)
            Button("Send", systemImage: "arrow.up") { }
              .labelStyle(.iconOnly)
              .fontWeight(.semibold)
              .buttonStyle(.borderedProminent)
          }
          .padding(8)
          .glassEffect(.regular.interactive())
        }
        .padding(.horizontal)
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
