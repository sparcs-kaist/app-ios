//
//  TaxiRoomCreationView.swift
//  soap
//
//  Created by Soongyu Kwon on 09/03/2025.
//

import SwiftUI

struct TaxiRoomCreationView: View {
  @State var viewModel: TaxiListViewModelProtocol
  @State var roomCreationViewModel = TaxiRoomCreationViewModel()
  @Environment(\.dismiss) private var dismiss

  @State private var title: String = ""
  @State private var showAlert: Bool = false
  @State private var alertMessage: String = ""
  @State private var alertTitle: String = ""

  init(viewModel: TaxiListViewModelProtocol = TaxiListViewModel()) {
    _viewModel = State(wrappedValue: viewModel)
  }

  var body: some View {
    NavigationView {
      Form {
        Section {
          TaxiDestinationPicker(
            source: $viewModel.source,
            destination: $viewModel.destination,
            locations: viewModel.locations
          )
        }

        Section {
          HStack {
            TextField("Title", text: $title)
          }
        }

        Section {
          TaxiDepartureTimePicker(departureTime: $viewModel.roomDepartureTime)
          Picker("Capacity", selection: $viewModel.roomCapacity) {
            ForEach(2...4, id: \.self) { number in
              Text("\(number) people")
                .tag(number)
            }
          }
        }
      }
      .navigationTitle("New Group")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel", systemImage: "xmark", role: .close) {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "arrow.up", role: .confirm) {
            Task {
              do {
                try await viewModel.createRoom(title: title)
                await viewModel.fetchData(inviteId: nil)
                dismiss()
              } catch {
                self.alertTitle = String(localized: "Error")
                self.alertMessage = error.localizedDescription
                self.showAlert = true
              }
            }
          }
          .disabled(!isValid)
        }
      }
    }
    .task {
      await roomCreationViewModel.fetchBlockStatus()
      switch roomCreationViewModel.blockStatus {
      case .error(let errorMessage):
        showAlert(title: String(localized: "Error"), message: errorMessage)
      case .notPaid:
        showAlert(title: String(localized: "Notice"), message: String(localized: "There are rooms for which settlement has not been completed. To create a room, please settle an existing room."))
      case .tooManyRooms:
        showAlert(title: String(localized: "Notice"), message: String(localized: "You are participating in more than 5 rooms. To create a room, please settle an existing room."))
      default: break
      }
    }
    .alert(alertTitle, isPresented: $showAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(alertMessage)
    })
  }
  
  private func isTitleValid(_ title: String) -> Bool {
    guard let regex = Constants.taxiRoomNameRegex else { return false }
    return title.wholeMatch(of: regex) != nil
  }
  
  private func showAlert(title: String, message: String) {
    self.alertTitle = title
    self.alertMessage = message
    self.showAlert = true
  }

  var isValid: Bool {
    viewModel.source != nil
    && viewModel.destination != nil
    && !title.isEmpty
    && viewModel.source != viewModel.destination
    && viewModel.roomDepartureTime > Date()
    && isTitleValid(title)
    && (roomCreationViewModel.blockStatus == .allow)
  }
}

#Preview {
  let vm = MockTaxiListViewModel()
  return TaxiRoomCreationView(viewModel: vm)
}
