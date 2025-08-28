//
//  AraSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct AraSettingsView: View {
  @State private var vm: AraSettingsViewModelProtocol
  @State private var showNicknameAlert: Bool = false
  @Environment(\.dismiss) private var dismiss
  
  init(vm: AraSettingsViewModelProtocol = AraSettingsViewModel()) {
    _vm = State(initialValue: vm)
  }
  
  var body: some View {
    Group {
      switch vm.state {
      case .loading:
        loadingView
      case .loaded:
        loadedView
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .task {
      await vm.fetchAraUser()
    }
    .onChange(of: [vm.araAllowNSFWPosts, vm.araAllowPoliticalPosts]) {
      Task {
        await vm.updateAraPostVisibility()
      }
    }
    .alert("Warning", isPresented: $showNicknameAlert) {
      Button(role: .cancel) {
        showNicknameAlert = false
      }
      Button(role: .confirm) {
        updateAraNickname()
      }
    } message: {
      Text("Nicknames can only be changed every 3 months. Change nickname to \(vm.araNickname)?")
    }
  }
  
  private var loadingView: some View {
    List {
      Section(header: Text("Profile")) {
        HStack {
          Text("Nickname")
          Spacer()
          TextField("Nickname", text: .constant("Unknown"))
        }
      }

      Section(header: Text("Posts")) {
        Toggle("Allow NSFW", isOn: .constant(true))
        Toggle("Allow Political", isOn: .constant(true))
      }
    }
    .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    List {
      Section {
        HStack {
          Text("Nickname")
          Spacer()
          TextField("Nickname", text: $vm.araNickname)
          .autocorrectionDisabled()
          .onSubmit {
            showNicknameAlert = true
          }
          .multilineTextAlignment(.trailing)
          .foregroundStyle(.secondary)
          .disabled(vm.araNicknameUpdatable == false)
        }
      } header: {
        Text("Profile")
      } footer: {
        VStack(alignment: .leading) {
          if vm.araNicknameUpdatable == false, let date = vm.araNicknameUpdatableSince {
            Text("You can't change nickname until \(date.formatted(.iso8601.year().month().day())).")
          }
          Text("Nicknames can only be changed every 3 months.")
        }
      }

      Section(header: Text("Post Setttings")) {
        Toggle("Allow NSFW", isOn: $vm.araAllowNSFWPosts)
        Toggle("Allow Political", isOn: $vm.araAllowPoliticalPosts)
      }
      
      NavigationLink(
        "My Posts",
        destination: AraMyPostView(vm: $vm)
          .navigationTitle("My Posts")
      )
    }
  }
  
  func updateAraNickname() {
    Task {
      do {
        try await vm.updateAraNickname()
      } catch {
        logger.debug("Failed to update Ara nickname: \(error.localizedDescription)")
      }
    }
  }
}

#Preview("Loading State") {
  let vm = MockAraSettingsViewModel()
  vm.state = .loading
  
  return NavigationStack {
    AraSettingsView(vm: vm)
  }
}

#Preview("Loaded State") {
  let vm = MockAraSettingsViewModel()
  vm.state = .loaded
  vm.araNickname = "오열하는 운영체제 및 실험"
  vm.araAllowNSFWPosts = false
  vm.araAllowPoliticalPosts = true
  
  return NavigationStack {
    AraSettingsView(vm: vm)
  }
}

#Preview("Error State") {
  let vm = MockAraSettingsViewModel()
  vm.state = .error(message: "Network error")
  
  return NavigationStack {
    AraSettingsView(vm: vm)
  }
}
