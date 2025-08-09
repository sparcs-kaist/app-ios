//
//  TaxiSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct TaxiSettingsView: View {
  @Binding var vm: SettingsViewModelProtocol
  
  var body: some View {
    List {
      switch vm.taxiState {
      case .loading:
        loadingView
          .redacted(reason: .placeholder)
      case .loaded:
        loadedView
      case .error(_):
        EmptyView()
      }
    }
    .task {
      await vm.fetchTaxiUser()
    }
  }
  
  @ViewBuilder
  var loadingView: some View {
    Group {
      RowElementView(title: "Nickname", content: "Unknown")
      RowElementView(title: "Bank Account", content: "Unknown")
    }
  }
  
  @ViewBuilder
  var loadedView: some View {
    Section(header: Text("Profile")) {
      RowElementView(title: "Nickname", content: vm.taxiUser?.nickname ?? "Unknown")
      HStack(alignment: .top) {
        VStack(alignment: .trailing) {
          Picker("Bank Account", selection: $vm.taxiBankName) {
            Text("Select Bank").tag(Optional<String>(nil))
            ForEach(Constants.taxiBankNameList, id: \.self) {
              Text($0).tag($0)
            }
          }
          Spacer()
          TextField("Enter Bank Number", text: $vm.taxiBankNumber)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

#Preview("Loading State") {
  let vm = MockSettingsViewModel()
  vm.taxiState = .loading
  
  return NavigationStack {
    TaxiSettingsView(vm: .constant(vm))
  }
}

#Preview("Loaded State") {
  let vm = MockSettingsViewModel()
  vm.taxiState = .loaded
  vm.taxiUser = .mock
  vm.taxiBankName = "KB국민"
  vm.taxiBankNumber = "123-456-7654"
  
  return NavigationStack {
    TaxiSettingsView(vm: .constant(vm))
  }
}
