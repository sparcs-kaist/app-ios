//
//  TaxiRecentSection.swift
//  soap
//
//  Created by Soongyu Kwon on 13/06/2025.
//

import SwiftUI
import BuddyDomain

struct TaxiRecentSection: View {
  var body: some View {
    VStack {
      HStack {
        Text("Taxi")
          .font(.title2)
          .fontWeight(.bold)

        Button("Navigate", systemImage: "chevron.right") { }
          .font(.caption)
          .labelStyle(.iconOnly)
          .buttonBorderShape(.circle)
          .buttonStyle(.borderedProminent)
          .tint(Color.systemBackground)
          .foregroundStyle(.secondary)

        Spacer()
      }
      .padding(.horizontal)

      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack {
          ForEach(TaxiRoom.mockList, id: \.id) { room in
            TaxiRoomCell(room: room)
              .frame(width: .screenWidth - 40)
              .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                effect
                  .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
              }
          }
        }
        .scrollTargetLayout()
        .padding(.horizontal)
      }
      .scrollTargetBehavior(.viewAligned)
    }
  }
}

#Preview {
  ZStack {
    Color.secondarySystemBackground

    TaxiRecentSection()
  }
  .ignoresSafeArea()
}
