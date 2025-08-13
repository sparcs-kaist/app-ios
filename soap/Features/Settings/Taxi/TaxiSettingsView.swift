//
//  TaxiSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct TaxiSettingsView: View {
  @Binding var vm: SettingsViewModelProtocol
  
  @Environment(\.dismiss) var dismiss
  
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
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done", systemImage: "checkmark", role: .confirm) {
          dismiss()
          Task {
            await vm.taxiEditBankAccount(account: "\(vm.taxiBankName!) \(vm.taxiBankNumber)")
          }
        }
        .disabled(!isValid)
      }
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
    
    Section(header: Text("Service")) {
      navigationLinkWithIcon(destination: TaxiReportDetailView(), text: "Report Details", systemImage: "exclamationmark.bubble")
      navigationLinkWithIcon(destination: TaxiNoticeView(), text: "Notice", systemImage: "bell")
      navigationLinkWithIcon(destination: TaxiTermsOfServiceView(isAgreed: vm.taxiUser?.agreeOnTermsOfService ?? false), text: "Terms of Service", systemImage: "list.clipboard")
      navigationLinkWithIcon(destination: TaxiPrivacyPolicyView(), text: "Privacy Policy", systemImage: "list.clipboard")
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
  vm.taxiBankName = String(vm.taxiUser!.account.split(separator: " ").first!)
  vm.taxiBankNumber = String(vm.taxiUser!.account.split(separator: " ").last!)
  
  return NavigationStack {
    TaxiSettingsView(vm: .constant(vm))
  }
}
