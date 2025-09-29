//
//  SearchSection.swift
//  soap
//
//  Created by 하정우 on 9/29/25.
//

import SwiftUI

struct SearchSection<Content: View, Destination: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content
  @ViewBuilder let destination: () -> Destination
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(title)
          .font(.title2)
          .fontWeight(.bold)
        NavigationLink {
          destination()
        } label: {
          Image(systemName: "chevron.right")
            .font(.caption)
            .labelStyle(.iconOnly)
            .foregroundStyle(.primary)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(Color.systemBackground)
        .foregroundStyle(.secondary)
        Spacer()
      }
      LazyVStack(alignment: .leading, spacing: 0) {
        content()
      }
      .background(Color.systemBackground)
      .clipShape(.rect(cornerRadius: 28.0))
    }
    .padding(.horizontal)
  }
}

#Preview {
  let rooms: [TaxiRoom] = []
  
  ZStack {
    Color.secondarySystemBackground
    
    VStack {
      SearchSection<SearchContent, TaxiListView>(title: "Rides") {
        SearchContent(results: Array(TaxiRoom.mockList[..<3])) {
          TaxiRoomCell(room: $0)
        }
      } destination: {
        TaxiListView()
      }
      
      SearchSection<SearchContent<TaxiRoom, TaxiRoomCell>, TaxiListView>(title: "Rides") {
        SearchContent<TaxiRoom, TaxiRoomCell>(results: rooms) {
          TaxiRoomCell(room: $0)
        }
      } destination: {
        TaxiListView()
      }
    }
  }
  .ignoresSafeArea()
}
