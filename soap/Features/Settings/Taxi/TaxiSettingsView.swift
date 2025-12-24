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
  @State private var showToggle: Bool = false
  
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
      withAnimation {
        showToggle = hasNumberRegistered
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
      Button(role: .cancel, action: {
        
      })
      
      Button(role: .confirm, action: {
        Task {
          await vm.editInformation()
          dismiss()
        }
      })
    }, message: {
      Text("Phone number can be set only once. Is the number you want to use correct?\n\n\(vm.phoneNumber)")
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
        }
        HStack {
          Text("Phone Number")
          Spacer()
          TextField("Enter Phone Number", text: $vm.phoneNumber)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
            .onChange(of: vm.phoneNumber) {
              vm.phoneNumber = vm.phoneNumber.formatPhoneNumber()
              withAnimation {
                showToggle = !vm.phoneNumber.isEmpty
              }
            }
            .disabled(hasNumberRegistered)
        }
        if showToggle {
          HStack {
            Toggle(isOn: $vm.showBadge, label: {
              Text("Show Badge")
            })
          }
          .transition(.slide.combined(with: .opacity.animation(.easeInOut(duration: 0.3))))
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
    vm.bankName != nil
    && !vm.bankNumber.isEmpty
    && (vm.phoneNumber.isEmpty || vm.phoneNumber.count == 13)
    && (hasNumberChanged || hasBankAccountChanged)
  }
  
  private var hasNumberRegistered: Bool {
    vm.user?.phoneNumber?.isEmpty == false
  }
  
  private var hasNumberChanged: Bool {
    vm.user?.phoneNumber == nil
    && vm.phoneNumber != ""
  }
  
  private var hasBankAccountChanged: Bool {
    guard let account = vm.user?.account,
            let name = account.split(separator: " ").first,
            let number = account.split(separator: " ").last else { return false }
    
    return String(name) != vm.bankName || String(number) != vm.bankNumber
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
