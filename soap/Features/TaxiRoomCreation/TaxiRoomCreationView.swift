//
//  TaxiRoomCreationView.swift
//  soap
//
//  Created by Soongyu Kwon on 09/03/2025.
//

import SwiftUI

struct TaxiRoomCreationView: View {
  @State var viewModel: TaxiListViewModelProtocol
  @State var roomCreationViewModel: TaxiRoomCreationViewModel = .init()
  @Environment(\.dismiss) private var dismiss

  @State private var title: String = ""
  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

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
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
              }
            }
          }
          .disabled(!isValid)
        }
      }
    }
    .alert("Error", isPresented: $showErrorAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(errorMessage)
    })
  }
  
  private func isTitleValid(_ title: String) -> Bool {
    do {
      let regex = try Regex(Constants.taxiRoomNameRegex)
      return title.wholeMatch(of: regex) != nil
    } catch {
      return false
    }
  }

  var isValid: Bool {
    return viewModel.source != nil && viewModel.destination != nil && !title.isEmpty && viewModel.source != viewModel.destination && viewModel.roomDepartureTime > Date() && isTitleValid(title) && !roomCreationViewModel.isNotPaid
  }
}

#Preview {
  let vm = MockTaxiListViewModel()
  return TaxiRoomCreationView(viewModel: vm)
}
