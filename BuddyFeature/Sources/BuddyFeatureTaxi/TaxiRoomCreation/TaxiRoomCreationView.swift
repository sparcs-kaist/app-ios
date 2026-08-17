//
//  TaxiRoomCreationView.swift
//  soap
//
//  Created by Soongyu Kwon on 09/03/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import FirebaseAnalytics
import BuddyPreviewSupport
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiRoomCreationView")

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
    NavigationStack {
      Form {
        Section {
          // A macOS Form is a two-column grid and takes a row's first subview as its
          // label — which split this picker's `HStack`, stranding the swap button in
          // the trailing column. `LabeledContent` with an empty label keeps the row
          // whole. iOS lays it out unchanged.
          LabeledContent {
            TaxiDestinationPicker(
              source: $viewModel.source,
              destination: $viewModel.destination,
              locations: viewModel.locations
            )
          } label: {
            EmptyView()
          }
        }

        Section(String(localized: "Title", bundle: .module)) {
          HStack {
            TextField(String(localized: "Title", bundle: .module), text: $title)
              #if os(macOS)
              // The section header already reads "Title"; macOS puts a field's own
              // label in the leading column too, so it appeared twice.
              .labelsHidden()
              #endif
          }
        }

        Section {
          TaxiDepartureTimePicker(departureTime: $viewModel.roomDepartureTime)
          Picker(String(localized: "Capacity", bundle: .module), selection: $viewModel.roomCapacity) {
            ForEach(2...4, id: \.self) { number in
              Text("\(number) people", bundle: .module)
                .tag(number)
            }
          }
          Toggle(String(localized: "With Luggage", bundle: .module), isOn: $viewModel.hasCarrier)
        }
      }
      .navigationTitle(String(localized: "New Group", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      #if os(macOS)
      // A Mac sheet sizes to its content, and this one came out too narrow for a
      // two-column form: the label column collided with the fields beside it.
      .frame(minWidth: 460)
      #endif
      .toolbar {
        ToolbarItem(placement: .sheetCancellation) {
          Button(String(localized: "Cancel", bundle: .module), systemImage: "xmark", role: .close) {
            dismiss()
          }
        }

        ToolbarItem(placement: .sheetConfirmation) {
          Button(String(localized: "Done", bundle: .module), systemImage: "arrow.up", role: .confirm) {
            Task {
              do {
                try await viewModel.createRoom(title: title)
                await viewModel.fetchData()
                dismiss()
              } catch {
                logger.error("Failed to create room: \(error.localizedDescription, privacy: .public)")
                self.alertTitle = String(localized: "Error", bundle: .module)
                self.alertMessage = error.localizedDescription
                self.showAlert = true
              }
            }
          }
          .disabled(!isValid)
        }
      }
    }
    .onAppear {
      if let randomTitle = Constants.taxiDefaultRoomNames.randomElement() {
        title = randomTitle
      }
    }
    .task {
      await roomCreationViewModel.fetchBlockStatus()
      switch roomCreationViewModel.blockStatus {
      case .error(let errorMessage):
        showAlert(title: String(localized: "Error", bundle: .module), message: errorMessage)
      case .notPaid:
        showAlert(title: String(localized: "Notice", bundle: .module), message: String(localized: "There are rooms for which settlement has not been completed. To create a room, please settle an existing room.", bundle: .module))
      case .tooManyRooms:
        showAlert(title: String(localized: "Notice", bundle: .module), message: String(localized: "You are participating in more than 5 rooms. To create a room, please settle an existing room.", bundle: .module))
      default: break
      }
    }
    .alert(alertTitle, isPresented: $showAlert, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text(alertMessage)
    })
    .analyticsScreen(name: "Taxi Room Creation", class: String(describing: Self.self))
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
  let state = TaxiListViewState.loaded(
    rooms: TaxiRoom.mockList,
    locations: TaxiLocation.mockList
  )
  
  TaxiRoomCreationView(viewModel: PreviewTaxiListViewModel(state: state))
}
