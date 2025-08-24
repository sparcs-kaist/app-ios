//
//  TaxiSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct TaxiSettingsView: View {
  @Binding var vm: SettingsViewModelProtocol
  @State private var safariURL: URL?
  
  @Environment(\.dismiss) var dismiss
  
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
      await vm.fetchTaxiUser()
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done", systemImage: "checkmark", role: .confirm) {
          dismiss()
          Task {
            guard let bankName = vm.taxiBankName else { return }
            await vm.taxiEditBankAccount(account: "\(bankName) \(vm.taxiBankNumber)")
          }
        }
        .disabled(!isValid)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .fullScreenCover(item: $safariURL) {
      SafariViewWrapper(url: $0)
    }
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
        RowElementView(title: "Nickname", content: vm.taxiUser?.nickname ?? "Unknown")
        Picker("Bank Name", selection: $vm.taxiBankName) {
          Text("Select Bank").tag(Optional<String>(nil))
          ForEach(Constants.taxiBankNameList, id: \.self) {
            Text($0).tag($0)
          }
        }
        HStack {
          Text("Bank Number")
          Spacer()
          TextField("Enter Bank Number", text: $vm.taxiBankNumber)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
        }
      }
      
      Section(header: Text("Service")) {
        navigationLinkWithIcon(destination: TaxiReportListView(), text: "Report Details", systemImage: "exclamationmark.bubble")
        webViewButton("list.bullet.clipboard", text: "Terms of Service", url: URL(string: "https://sparcs.org")!)
        webViewButton("list.bullet.clipboard", text: "Privacy Policy", url: URL(string: "https://sparcs.org")!)
      }
    }
  }
  
  var isValid: Bool {
    return vm.taxiBankName != nil && !vm.taxiBankNumber.isEmpty && (vm.taxiUser?.account != "\(vm.taxiBankName ?? "") \(vm.taxiBankNumber)")
  }
  
  fileprivate func navigationLinkWithIcon(destination: some View, text: String, systemImage: String) -> some View {
    NavigationLink(destination: destination.navigationTitle(text).navigationBarTitleDisplayMode(.inline)) {
      HStack(alignment: .center) {
        Image(systemName: systemImage)
        Text(text)
      }
    }
  }
  
  fileprivate func webViewButton(_ systemImage: String, text: String, url: URL) -> some View {
    NavigationLink(value: UUID()) {
      Image(systemName: systemImage)
      Text(text)
    }
    .onTapGesture {
      safariURL = url
    }
  }
}

#Preview("Loading State") {
  let vm = MockSettingsViewModel()
  vm.state = .loading
  
  return NavigationStack {
    TaxiSettingsView(vm: .constant(vm))
  }
}

#Preview("Loaded State") {
  let vm = MockSettingsViewModel()
  vm.state = .loaded
  vm.taxiUser = .mock
  vm.taxiBankName = String(vm.taxiUser!.account.split(separator: " ").first!)
  vm.taxiBankNumber = String(vm.taxiUser!.account.split(separator: " ").last!)
  
  return NavigationStack {
    TaxiSettingsView(vm: .constant(vm))
  }
}

#Preview("Error State") {
  let vm = MockSettingsViewModel()
  vm.state = .error(message: "Network error")
  
  return NavigationStack {
    TaxiSettingsView(vm: .constant(vm))
  }
}
