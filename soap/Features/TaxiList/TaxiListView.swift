//
//  TaxiListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/07/2025.
//

import SwiftUI

struct TaxiListView: View {
  @State private var origin: TaxiLocationOld?
  @State private var destination: TaxiLocationOld?
  @State private var locations: [TaxiLocationOld] = TaxiLocationOld.mockList
  @State private var selectedDate: Date = Date()

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(pinnedViews: .sectionHeaders) {
          TaxiDestinationPicker(origin: $origin, destination: $destination, locations: locations)
            .padding()
            .background(Color.systemBackground, in: .rect(cornerRadius: 26))
            .padding(.horizontal)

          Section {
            ForEach(0..<100) { _ in
              Text("test")
            }
          } header: {
            WeekDaySelector(selectedDate: $selectedDate)
              .padding(.horizontal)
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Create", systemImage: "plus") { }
        }
      }
      .navigationTitle("Taxi")
      .background(Color.secondarySystemBackground)
    }
  }
}


#Preview {
  TaxiListView()
}
