//
//  TaxiRecentSection.swift
//  soap
//
//  Created by Soongyu Kwon on 13/06/2025.
//

import SwiftUI

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
          ForEach(RoomInfo.mockList, id: \.name) { room in
            VStack(alignment: .leading, spacing: 12) {
              HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                  Label(room.origin.title, systemImage: "location.fill")
                  Label(room.destination.title, systemImage: "flag.pattern.checkered")
                }
                .fontWeight(.medium)

                Spacer()

                HStack(spacing: 4) {
                  Text("\(room.occupancy)/\(room.capacity)")
                  Image(systemName: "person.2")
                }
                .font(.footnote)
                .foregroundStyle(.green)
                .padding(4)
                .background(.green.opacity(0.1))
                .clipShape(.rect(cornerRadius: 4))
              }

              Text(room.departureTime.relativeTimeString + "\tLorem ipsum")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .frame(width: .screenWidth - 80)
            .padding()
            .background(Color.systemBackground)
            .clipShape(.rect(cornerRadius: 28))
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
