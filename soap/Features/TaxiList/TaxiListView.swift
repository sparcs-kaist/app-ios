//
//  TaxiListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/07/2025.
//

import SwiftUI

struct TaxiListView: View {
  @State private var origin: TaxiLocation?
  @State private var destination: TaxiLocation?
  @State private var locations: [TaxiLocation] = TaxiLocation.mockList

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack {
          TaxiDestinationPicker(origin: $origin, destination: $destination, locations: locations)
            .padding()
            .background(Color.secondarySystemBackground)
            .clipShape(.rect(cornerRadius: 26))
            .padding()
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Create a New Room", systemImage: "plus") { }
        }
      }
      .navigationTitle("Taxi")
    }
  }
}


#Preview {
  TaxiListView()
}
