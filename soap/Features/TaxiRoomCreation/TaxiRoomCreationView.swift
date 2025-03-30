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
            DiceButton(action: {
              if let randomName = TaxiRoomCreationViewModel.randomRoomNames.randomElement() {
                viewModel.roomName = randomName
              }
            })
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

  struct DiceButton: View {
    var action: () -> Void

    @State private var isRolling = false
    @State private var angle: Double = 0

    var body: some View {
      Button(action: {
        withAnimation {
          angle += 360
        }
        action()
      }) {
        Label("generate", systemImage: "dice.fill")
          .rotationEffect(.degrees(angle))
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.bordered)
      .buttonBorderShape(.circle)
    }
  }
}

#Preview {
  TaxiRoomCreationView()
}
