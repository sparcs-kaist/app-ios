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
    ZStack(alignment: .leading) {
      VStack(alignment: .leading) {
        Menu {
          if origin == nil {
            Button("where from?") {
              withAnimation(.spring()) { origin = nil }
            }
          }
          ForEach(locations) { location in
            Button(location.title) {
              withAnimation(.spring()) { origin = location }
            }
          }
        } label: {
          HStack {
            Text(origin?.title ?? "where from?")
              .contentTransition(.numericText())
            Image(systemName: "chevron.up.chevron.down")
          }
        }
        .padding(4)
        .tint(.black)
        .font(.callout)

        Menu {
          if destination == nil {
            Button("where to?") {
              withAnimation(.spring()) { destination = nil }
            }
          }
          ForEach(locations) { location in
            Button(location.title) {
              withAnimation(.spring()) { destination = location }
            }
          }
        } label: {
          HStack {
            Text(destination?.title ?? "where to?")
              .contentTransition(.numericText())
            Image(systemName: "chevron.up.chevron.down")
          }
        }
        .padding(4)
        .tint(.black)
        .font(.callout)
      }

      HStack {
        Rectangle()
          .frame(height: 1)
          .foregroundStyle(Color(uiColor: .systemGray5))
        
        Button(action: {
          withAnimation(.easeInOut(duration: 0.6)) {
            isFlipped.toggle()
          }

          // Delay swap until halfway through flip for realism
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            swap(&origin, &destination)
          }
        }) {
          Label("swap", systemImage: "arrow.trianglehead.swap")
            .rotation3DEffect(
              .degrees(isFlipped ? 180 : 0),
              axis: (x: isFlipped ? -1 : 1, y: 0, z: 0)
            )
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
      }
    }
  }
}

#if DEBUG

fileprivate struct TaxiDestinationPickerPreview: View {
  @State private var origin: TaxiLocation?
  @State private var destination: TaxiLocation?
  @State private var locations: [TaxiLocation] = TaxiLocation.mockList

  var body: some View {
    Form {
      Section {

        TaxiDestinationPicker(origin: $origin, destination: $destination, locations: locations)
          .onChange(of: origin) {
            print("origin: \(origin?.title)")
          }
          .onChange(of: destination) {
            print("destination: \(destination?.title)")
          }
      }
    }
  }
}

#Preview {
  TaxiDestinationPickerPreview()
}

#endif

