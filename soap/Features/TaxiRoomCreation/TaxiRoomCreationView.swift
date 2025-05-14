//
//  TaxiRoomCreationView.swift
//  soap
//
//  Created by Soongyu Kwon on 09/03/2025.
//

import SwiftUI

struct TaxiRoomCreationView: View {
  @State private var viewModel = TaxiRoomCreationViewModel()

  var body: some View {
    NavigationView {
      Form {
        Section {
          TaxiDestinationPicker(
            origin: $viewModel.origin,
            destination: $viewModel.destination,
            locations: viewModel.locations
          )
        }

        Section(header: Text("Title")) {
          HStack {
            TextField("Title", text: $viewModel.roomName)
          }
        }

        Section {
          TaxiDepatureTimePicker(depatureTime: $viewModel.roomDepatureTime)
          Picker("Capacity", selection: $viewModel.roomCapacity) {
            ForEach(2...4, id: \.self) { number in
              Text("\(number) people")
                .tag(number)
            }
          }
        }
      }
      .navigationTitle("New Room")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            // TODO: dismiss
          }
        }
      }
    }
  }
}

#Preview {
  TaxiRoomCreationView()
}
