//
//  TaxiRoomCreationView.swift
//  soap
//
//  Created by Soongyu Kwon on 09/03/2025.
//

import SwiftUI

struct TaxiRoomCreationView: View {
  @State var viewModel: TaxiListViewModelProtocol
  @Environment(\.dismiss) private var dismiss

  @State private var title: String = "new room"

  init(viewModel: TaxiListViewModelProtocol = TaxiListViewModel()) {
    _viewModel = State(wrappedValue: viewModel)
  }

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Location")) {
          TaxiDestinationPicker(
            origin: $viewModel.origin,
            destination: $viewModel.destination,
            locations: viewModel.locations
          )
        }

        Section(header: Text("Title")) {
          HStack {
            TextField("Title", text: $title)
          }
        }

        Section(header: Text("detail")) {
          TaxiDepartureTimePicker(departureTime: $viewModel.roomDepartureTime)
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
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel", systemImage: "xmark", role: .close) {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "arrow.up", role: .confirm) {
            dismiss()
          }
          .disabled(viewModel.origin == nil || viewModel.destination == nil)
        }
      }
    }
  }
}

#Preview {
  let vm = MockTaxiListViewModel()
  return TaxiRoomCreationView(viewModel: vm)
}
