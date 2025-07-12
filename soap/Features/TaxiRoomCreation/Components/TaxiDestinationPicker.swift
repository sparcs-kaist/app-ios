//
//  TaxiDestinationPicker.swift
//  soap
//
//  Created by Soongyu Kwon on 23/03/2025.
//

import SwiftUI
import MapKit

struct TaxiDestinationPicker: View {
  @Binding var origin: TaxiLocation?
  @Binding var destination: TaxiLocation?
  let locations: [TaxiLocation]

  @State private var isFlipped = false

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 12) {
        LocationMenu(title: "meeting point", selection: $origin, locations: locations)

        Divider()

        LocationMenu(title: "where to?", selection: $destination, locations: locations)
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
    .padding(4)
  }

  private func swapLocations() {
    withAnimation(.easeInOut) {
      isFlipped.toggle()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      swap(&origin, &destination)
    }
  }
}

fileprivate struct LocationMenu: View {
  let title: String
  @Binding var selection: TaxiLocation?
  let locations: [TaxiLocation]

  var body: some View {
    Menu {
      Button(title) {
        withAnimation(.spring()) {
          selection = nil
        }
      }
      ForEach(locations) { location in
        Button(location.title.localized()) {
          withAnimation(.spring()) {
            selection = location
          }
        }
      }
    } label: {
      HStack {
        Text(selection?.title.localized() ?? title)
          .contentTransition(.numericText())
        Image(systemName: "chevron.up.chevron.down")
        Spacer()
      }
      .tint(.black)
      .font(.callout)
    }
  }
}

#if DEBUG

fileprivate struct TaxiDestinationPickerPreview: View {
  @State private var origin: TaxiLocation?
  @State private var destination: TaxiLocation?
  @State private var locations: [TaxiLocation] = TaxiLocation.mockList

  var body: some View {
    TaxiDestinationPicker(origin: $origin, destination: $destination, locations: locations)
  }
}

#Preview {
  TaxiDestinationPickerPreview()
}

#endif

