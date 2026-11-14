//
//  MapSummaryCards.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import BuddyDomain

/// Category filters as a row of glass capsules floating over the map; tapping the selected one
/// clears it.
struct PlaceFilterChips: View {
  @Binding var selection: CampusPlaceFilter?

  var body: some View {
    ScrollView(.horizontal) {
      GlassEffectContainer(spacing: 8) {
        HStack(spacing: 8) {
          ForEach(CampusPlaceFilter.allCases) { filter in
            let isSelected = selection == filter
            Button {
              withAnimation(.snappy) {
                selection = isSelected ? nil : filter
              }
            } label: {
              Label(filter.title, systemImage: filter.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .glassEffect(isSelected ? .regular.tint(filter.tint).interactive() : .regular.interactive(), in: .capsule)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
      }
    }
    .scrollIndicators(.hidden)
  }
}

/// A place as a glass card in the row along the bottom of the map: what it is and the one fact
/// worth knowing before walking there.
struct PlaceCarouselCard: View {
  let place: CampusPlace
  let viewModel: CampusMapViewModelProtocol

  var body: some View {
    HStack(spacing: 10) {
      PlaceIcon(category: place.category, size: 40)

      VStack(alignment: .leading, spacing: 2) {
        Text(place.displayName)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        statusLine
          .font(.caption)
          .lineLimit(1)
      }

      Spacer(minLength: 0)
    }
    .padding(12)
    .frame(width: 216)
    .contentShape(.rect)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24, style: .continuous))
  }

  @ViewBuilder
  private var statusLine: some View {
    if place.category == .olevStop, let next = viewModel.olevTimetable.arrivals(at: place.id, around: .now).next {
      Text("Next bus \(next.olevCountdownText())", bundle: .module)
        .foregroundStyle(.blue)
    } else if let status = place.openingHours?.status(at: .now) {
      HStack(spacing: 4) {
        Text(status.title)
          .foregroundStyle(status.tint)
        Text(verbatim: "·")
        Text(viewModel.distance(to: place).distanceText)
      }
      .foregroundStyle(.secondary)
    } else {
      Text(viewModel.distance(to: place).distanceText)
        .foregroundStyle(.secondary)
    }
  }
}
