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
  @State private var showAlert: Bool = false
  
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
    .animation(.spring, value: showToggle)
    .task {
      await vm.fetchUser()
      if !hasNumberRegistered {
        vm.showBadge = true // showBadge defaults to true for users without a registered phone number
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done", systemImage: "checkmark", role: .confirm) {
          Task {
            if hasNumberChanged {
              showAlert = true
              return
            }
            await vm.editInformation()
            dismiss()
          }
        }
        .disabled(!isValid)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .fullScreenCover(item: $safariURL) {
      SafariViewWrapper(url: $0)
    }
    .navigationTitle("Taxi")
    .alert("Warning", isPresented: $showAlert, actions: {
      Button(role: .cancel) { }
      
      Button(role: .confirm, action: {
        Task {
          await vm.editInformation()
          dismiss()
        }
      }, label: {
        Text("Confirm")
      })
    }, message: {
      Text("Phone number can be set only once. Is the number you want to use correct?\n\n\(vm.phoneNumber.formatPhoneNumber())")
    })
  }
  
  @ViewBuilder
  var loadingView: some View {
    List {
      RowElementView(title: "Nickname", content: "Unknown")
      RowElementView(title: "Bank Account", content: "Unknown")
      RowElementView(title: "Phone Number", content: "Unknown")
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
            .keyboardType(.numberPad)
            .onChange(of: vm.bankNumber) {
              vm.bankNumber = vm.bankNumber.filter { $0.isASCIINumber }
            }
        }
        HStack {
          Text("Phone Number")
          Spacer()
          TextField("Enter Phone Number", text: $vm.phoneNumber)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
            .disabled(hasNumberRegistered)
            .onChange(of: vm.phoneNumber) {
              vm.phoneNumber = String(
                vm.phoneNumber
                  .prefix(Constants.phoneNumberLength)
                  .filter { $0.isASCIINumber }
              )
            }
        }
        if showToggle {
          HStack {
            Toggle(isOn: $vm.showBadge, label: {
              Text("Show Badge")
            })
          }
          .transition(.slide)
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
  
  private var isValid: Bool {
    (isBankAccountValid && isPhoneNumberValid)
    && (hasNumberChanged || hasBankAccountChanged || (hasNumberRegistered && hasBadgeChanged))
  }
  
  private var isBankAccountValid: Bool {
    (vm.bankName != nil && !vm.bankNumber.isEmpty) || (vm.bankName == nil && vm.bankNumber.isEmpty)
  }
  
  private var isPhoneNumberValid: Bool {
    vm.phoneNumber.isEmpty
    || (vm.phoneNumber.count == Constants.phoneNumberLength && vm.phoneNumber.allSatisfy { $0.isASCIINumber })
  }
  
  private var hasNumberRegistered: Bool {
    vm.user?.phoneNumber?.isEmpty == false
  }
  
  private var hasNumberChanged: Bool {
    vm.user?.phoneNumber?.isEmpty != false
    && !vm.phoneNumber.isEmpty
  }
  
  private var hasBadgeChanged: Bool {
    vm.user?.badge != vm.showBadge
  }
  
  private var hasBankAccountChanged: Bool {
    guard let account = vm.user?.account, !account.isEmpty else {
      return (vm.bankName?.isEmpty == false) || !vm.bankNumber.isEmpty
    }
    
    let components = account.split(separator: " ")
    
    if let name = components.first, let number = components.last {
      return (String(name) != vm.bankName) || (String(number) != vm.bankNumber)
    }
    
    return (vm.bankName?.isEmpty == false) || !vm.bankNumber.isEmpty
  }
  
  private var showToggle: Bool {
    vm.phoneNumber.count == Constants.phoneNumberLength
    && vm.phoneNumber.allSatisfy { $0.isASCIINumber }
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
