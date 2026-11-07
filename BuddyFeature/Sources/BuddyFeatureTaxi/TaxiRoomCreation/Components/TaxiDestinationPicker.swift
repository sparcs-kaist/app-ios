//
//  TaxiDestinationPicker.swift
//  soap
//
//  Created by Soongyu Kwon on 23/03/2025.
//

import Foundation
import SwiftUI
import MapKit
import BuddyDomain
import Haptica

/// Where the ride leaves from and goes to, marked like the route on a room card: the location
/// symbol for the departure, a dot for the destination and a line between them. Each row opens
/// its list of places whether or not one is chosen, and a chosen place can be cleared beside it.
struct TaxiDestinationPicker: View {
  @Binding var source: TaxiLocation?
  @Binding var destination: TaxiLocation?
  let locations: [TaxiLocation]

  @ScaledMetric private var rowHeight: CGFloat = 46
  @ScaledMetric private var markerSize: CGFloat = 16

  var body: some View {
    HStack(spacing: 12) {
      VStack(spacing: 0) {
        LocationRow(
          placeholder: String(localized: "meeting point", bundle: .module),
          isOrigin: true,
          selection: $source,
          // The other end of the route can't be this end too.
          locations: locations.filter { $0 != destination },
          markerSize: markerSize
        )
        .frame(minHeight: rowHeight)

        Divider()
          .padding(.leading, markerSize + 12)

        LocationRow(
          placeholder: String(localized: "where to?", bundle: .module),
          isOrigin: false,
          selection: $destination,
          locations: locations.filter { $0 != source },
          markerSize: markerSize
        )
        .frame(minHeight: rowHeight)
      }
      // The line joining the two markers, from below the first to above the second.
      .overlay(alignment: .leading) {
        Rectangle()
          .fill(.tertiary)
          .frame(width: 1.5, height: rowHeight - markerSize - 4)
          .padding(.leading, (markerSize - 1.5) / 2)
          .accessibilityHidden(true)
      }

      Button(action: swapLocations) {
        Label(String(localized: "swap", bundle: .module), systemImage: "arrow.up.arrow.down")
          .labelStyle(.iconOnly)
          .font(.body.weight(.semibold))
          .frame(width: 40, height: 40)
          .background(Color.accentColor.opacity(0.12), in: .circle)
      }
      .buttonStyle(.plain)
      .foregroundStyle(Color.accentColor)
      .disabled(source == nil && destination == nil)
    }
    .padding(.horizontal, 4)
    // The picker is on screen wherever favourites are, so it refreshes them for this account.
    .onAppear { TaxiFavorites.shared.reload() }
  }

  private func swapLocations() {
    Haptic.selection.generate()
    withAnimation(.snappy) {
      swap(&source, &destination)
    }
  }
}

/// One end of the route: a menu across the whole row, and a button to clear the place once one is
/// chosen.
fileprivate struct LocationRow: View {
  let placeholder: String
  let isOrigin: Bool
  @Binding var selection: TaxiLocation?
  let locations: [TaxiLocation]
  let markerSize: CGFloat

  private var favorites: TaxiFavorites { .shared }

  var body: some View {
    let favoritePlaces = locations.filter(favorites.isFavorite)

    HStack(spacing: 8) {
      Menu {
        // First, one section of your favourites: adding or removing the chosen place, in reach
        // without scrolling a long list, then your favourite places, starred. They are toggles
        // rather than an inline picker, which a menu always sets apart in a section of its own;
        // a toggle still shows the tick on the one chosen.
        if selection != nil || !favoritePlaces.isEmpty {
          Section {
            if let selection {
              if favorites.isFavorite(selection) {
                Button(String(localized: "Remove from Favourites", bundle: .module), systemImage: "star.slash") {
                  favorites.toggleFavorite(selection)
                }
              } else {
                Button(String(localized: "Add to Favourites", bundle: .module), systemImage: "star") {
                  favorites.toggleFavorite(selection)
                }
              }
            }

            ForEach(favoritePlaces) { location in
              Toggle(isOn: isChosen(location)) {
                Label(location.title.localized(), systemImage: "star.fill")
              }
            }
          }
        }

        // Then every other place, ticking the one chosen.
        Picker(selection: $selection, label: EmptyView()) {
          ForEach(locations.filter { !favorites.isFavorite($0) }) { location in
            Text(location.title.localized())
              .tag(location as TaxiLocation?)
          }
        }
        .pickerStyle(.inline)

      } label: {
        HStack(spacing: 12) {
          marker
            .foregroundStyle(selection == nil ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))

          Text(selection?.title.localized() ?? placeholder)
            .font(.body.weight(selection == nil ? .regular : .semibold))
            .foregroundStyle(selection == nil ? .secondary : .primary)
            .lineLimit(1)

          if let selection, favorites.isFavorite(selection) {
            Image(systemName: "star.fill")
              .font(.caption2)
              .foregroundStyle(.yellow)
              .accessibilityLabel(Text("Favourite Places", bundle: .module))
          }

          Spacer(minLength: 0)

          if selection == nil {
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.tertiary)
          }
        }
        .frame(maxHeight: .infinity)
        .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(placeholder)
      .accessibilityValue(selection?.title.localized() ?? "")

      if selection != nil {
        Button {
          withAnimation(.spring) { selection = nil }
        } label: {
          Label(String(localized: "Remove", bundle: .module), systemImage: "xmark.circle.fill")
            .labelStyle(.iconOnly)
            .font(.body)
            .foregroundStyle(.tertiary)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .transition(.opacity)
      }
    }
  }

  /// Whether `location` is the chosen place, as a toggle: turning it on chooses it, and turning
  /// the chosen one off leaves it chosen, as picking it again from a list would.
  private func isChosen(_ location: TaxiLocation) -> Binding<Bool> {
    Binding {
      selection == location
    } set: { isOn in
      if isOn { selection = location }
    }
  }

  @ViewBuilder
  private var marker: some View {
    Group {
      if isOrigin {
        Image(systemName: "location.circle.fill")
          .resizable()
          .scaledToFit()
      } else {
        Circle()
          .frame(width: markerSize * 0.7, height: markerSize * 0.7)
      }
    }
    .frame(width: markerSize, height: markerSize)
    .accessibilityHidden(true)
  }
}

#Preview {
  @Previewable @State var source: TaxiLocation?
  @Previewable @State var destination: TaxiLocation?
  @Previewable @State var locations: [TaxiLocation] = TaxiLocation.mockList

  LazyVStack {
    TaxiDestinationPicker(source: $source, destination: $destination, locations: locations)
      .padding()
      .background(Color.secondarySystemGroupedBackground, in: .rect(cornerRadius: 28))
      .padding(.horizontal)
  }
}
