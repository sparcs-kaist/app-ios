//
//  TaxiSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI
import BuddyDomain

struct TaxiSettingsView: View {
  @State private var vm: TaxiSettingsViewModelProtocol
  @State private var safariURL: URL?
  @State private var isValid: Bool = false
  
  @Environment(\.dismiss) var dismiss
  
  init(vm: TaxiSettingsViewModelProtocol = TaxiSettingsViewModel()) {
    _vm = State(initialValue: vm)
  }
  
  var body: some View {
    Group {
      switch vm.state {
      case .loading:
        loadingView
          .redacted(reason: .placeholder)
      case .loaded:
        loadedView
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .task {
      await vm.fetchUser()
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done", systemImage: "checkmark", role: .confirm) {
          dismiss()
          Task {
            guard let bankName = vm.bankName else { return }
            await vm.editBankAccount(account: "\(bankName) \(vm.bankNumber)")
          }
        }
        .disabled(!isValid)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .fullScreenCover(item: $safariURL) {
      SafariViewWrapper(url: $0)
    }
    .onChange(of: [vm.bankName, vm.bankNumber]) {
      isValid = vm.bankName != nil && !vm.bankNumber.isEmpty && (vm.user?.account != "\(vm.bankName ?? "") \(vm.bankNumber)")
    }
    .navigationTitle("Taxi")
  }
  
  @ViewBuilder
  var loadingView: some View {
    List {
      RowElementView(title: "Nickname", content: "Unknown")
      RowElementView(title: "Bank Account", content: "Unknown")
    }
  }
  
  @ViewBuilder
  var loadedView: some View {
    List {
      Section(header: Text("Profile")) {
        RowElementView(title: String(localized: "Nickname"), content: vm.user?.nickname ?? String(localized: "Unknown"))
        Picker("Bank Name", selection: $vm.bankName) {
          Text("Select Bank").tag(Optional<String>(nil))
          ForEach(Constants.taxiBankNameList, id: \.self) {
            Text($0).tag($0)
          }
        }
        HStack {
          Text("Bank Number")
          Spacer()
          TextField("Enter Bank Number", text: $vm.bankNumber)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
        }
      }
      
      Section(header: Text("Service")) {
        navigationLinkWithIcon(destination: TaxiReportListView(), text: String(localized: "Report Details"), systemImage: "exclamationmark.bubble")
      }
    }
  }
  
  fileprivate func navigationLinkWithIcon(destination: some View, text: String, systemImage: String) -> some View {
    NavigationLink(destination: destination.navigationTitle(text).navigationBarTitleDisplayMode(.inline)) {
      HStack(alignment: .center) {
        Image(systemName: systemImage)
        Text(text)
      }
    }
  }
}

#Preview("Loading State") {
  let vm = MockTaxiSettingsViewModel()
  vm.state = .loading
  
  return NavigationStack {
    TaxiSettingsView(vm: vm)
  }
}

#Preview("Loaded State") {
  let vm = MockTaxiSettingsViewModel()
  vm.state = .loaded
  vm.bankName = String(vm.user!.account.split(separator: " ").first!)
  vm.bankNumber = String(vm.user!.account.split(separator: " ").last!)
  
  return NavigationStack {
    TaxiSettingsView(vm: vm)
  }
}

#Preview("Error State") {
  let vm = MockTaxiSettingsViewModel()
  vm.state = .error(message: "Network error")
  
  return NavigationStack {
    TaxiSettingsView(vm: vm)
  }
}
