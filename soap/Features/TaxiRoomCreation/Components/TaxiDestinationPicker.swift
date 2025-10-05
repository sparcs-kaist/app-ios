//
//  TaxiDestinationPicker.swift
//  soap
//
//  Created by Soongyu Kwon on 23/03/2025.
//

import SwiftUI
import MapKit
import BuddyDomain
import BuddyDataMocks

struct TaxiDestinationPicker: View {
  @Binding var source: TaxiLocation?
  @Binding var destination: TaxiLocation?
  let locations: [TaxiLocation]

  @State private var isFlipped = false

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        LocationMenu(title: String(localized: "meeting point"), selection: $source, locations: locations)

        Divider()

        LocationMenu(title: String(localized: "where to?"), selection: $destination, locations: locations)
      }

      Button(action: swapLocations) {
        Label("swap", systemImage: "arrow.trianglehead.swap")
          .labelStyle(.iconOnly)
          .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: isFlipped ? -1 : 1, y: 0, z: 0)
          )
          .animation(.easeInOut(duration: 0.4), value: isFlipped)
      }
      .buttonStyle(.bordered)
      .buttonBorderShape(.circle)
    }
    .padding(.horizontal, 4)
  }

  private func swapLocations() {
    withAnimation(.easeInOut) {
      isFlipped.toggle()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      swap(&source, &destination)
    }
  }
}

fileprivate struct LocationMenu: View {
  let title: String
  @Binding var selection: TaxiLocation?
  let locations: [TaxiLocation]

  var body: some View {
    Picker(selection: $selection, label: EmptyView()) {
      Text(title)
        .tag(nil as TaxiLocation?)

      ForEach(locations) { location in
        Text(location.title.localized())
          .tag(location as TaxiLocation?)
      }
    }
    .pickerStyle(.menu)
    .tint(.primary)
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
