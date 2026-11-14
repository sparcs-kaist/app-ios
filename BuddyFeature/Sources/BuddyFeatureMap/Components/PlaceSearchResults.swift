//
//  PlaceSearchResults.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import BuddyDomain

/// Places as one grouped card of rows, the way Apple Maps lists results in its sheet.
struct PlaceListCard: View {
  let places: [CampusPlace]
  let viewModel: CampusMapViewModelProtocol
  let onSelect: (CampusPlace) -> Void

  var body: some View {
    VStack(spacing: 0) {
      ForEach(places) { place in
        Button {
          onSelect(place)
        } label: {
          HStack {
            PlaceRow(place: place, viewModel: viewModel)
            Image(systemName: "chevron.right")
              .font(.footnote.weight(.semibold))
              .foregroundStyle(.tertiary)
          }
          .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .contextMenu {
          Button(
            viewModel.isPinned(place) ? String(localized: "Unpin", bundle: .module) : String(localized: "Pin", bundle: .module),
            systemImage: viewModel.isPinned(place) ? "pin.slash" : "pin"
          ) {
            withAnimation { viewModel.togglePin(place) }
          }
        }

        if place.id != places.last?.id {
          Divider().padding(.leading, 52)
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 4)
    .background(.fill.quaternary, in: .rect(cornerRadius: 22, style: .continuous))
  }
}

/// Search results, nearest first.
struct PlaceSearchResults: View {
  let viewModel: CampusMapViewModelProtocol
  let query: String
  let onSelect: (CampusPlace) -> Void

  var body: some View {
    let results = viewModel.search(query)

    if results.isEmpty {
      ContentUnavailableView.search(text: query)
    } else {
      PlaceListCard(places: results, viewModel: viewModel, onSelect: onSelect)
    }
  }
}
