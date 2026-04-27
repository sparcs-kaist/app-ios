//
//  AraSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import Foundation
import SwiftUI
import BuddyDomain
import FirebaseAnalytics

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
        ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .task {
      await vm.fetchUser()
    }
    .onChange(of: [vm.allowNSFW, vm.allowPolitical]) {
      Task {
        await vm.updateContentPreference()
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .alert(String(localized: "Warning", bundle: .module), isPresented: $showNicknameAlert) {
      Button(role: .cancel) {
        showNicknameAlert = false
      }
      Button(role: .confirm) {
        updateAraNickname()
      }
    } message: {
      Text("Nicknames can only be changed every 3 months. Change nickname to \(vm.nickname)?", bundle: .module)
    }
    .navigationTitle(String(localized: "Ara", bundle: .module))
    .analyticsScreen(name: "Ara Settings", class: String(describing: Self.self))
  }
  
  private var loadingView: some View {
    List {
      Section(header: Text("Profile", bundle: .module)) {
        HStack {
          Text("Nickname", bundle: .module)
          Spacer()
          TextField(String(localized: "Nickname", bundle: .module), text: .constant(String(localized: "Unknown", bundle: .module)))
        }
      }

      Section(header: Text("Posts", bundle: .module)) {
        Toggle(String(localized: "Allow NSFW", bundle: .module), isOn: .constant(true))
        Toggle(String(localized: "Allow Political", bundle: .module), isOn: .constant(true))
      }
    }
    .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    List {
      Section {
        HStack {
          Text("Nickname", bundle: .module)
          Spacer()
          TextField(String(localized: "Nickname", bundle: .module), text: $vm.nickname)
          .autocorrectionDisabled()
          .onSubmit {
            showNicknameAlert = true
          }
          .multilineTextAlignment(.trailing)
          .foregroundStyle(.secondary)
          .disabled(vm.nicknameUpdatable == false)
        }
      } header: {
        Text("Profile", bundle: .module)
      } footer: {
        VStack(alignment: .leading) {
          if vm.nicknameUpdatable == false, let date = vm.nicknameUpdatableFrom {
            Text("You can't change nickname until \(date.formatted(.iso8601.year().month().day())).", bundle: .module)
          }
          Text("Nicknames can only be changed every 3 months.", bundle: .module)
        }
      }

      Section(header: Text("Content Preferences", bundle: .module)) {
        Toggle(String(localized: "Allow NSFW", bundle: .module), isOn: $vm.allowNSFW)
        Toggle(String(localized: "Allow Political", bundle: .module), isOn: $vm.allowPolitical)
      }
      
      Section(header: Text("Posts", bundle: .module)){
        NavigationLink(
          String(localized: "My Posts", bundle: .module),
          destination: AraMyPostView(user: vm.user, type: .all)
            .navigationTitle(String(localized: "My Posts", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        )
        NavigationLink(
          String(localized: "Bookmarked Posts", bundle: .module),
          destination: AraMyPostView(user: vm.user, type: .bookmark)
            .navigationTitle(String(localized: "Bookmarked Posts", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        )
      }
    }
  }
  
  func updateAraNickname() {
    Task {
      do {
        try await vm.updateNickname()
      } catch {
//        logger.error("Failed to update Ara nickname: \(error.localizedDescription)")
      }
    }
  }
}

//#Preview("Loading State") {
//  let vm = MockAraSettingsViewModel()
//  vm.state = .loading
//  
//  return NavigationStack {
//    AraSettingsView(vm: vm)
//  }
//}
//
//#Preview("Loaded State") {
//  let vm = MockAraSettingsViewModel()
//  vm.state = .loaded
//  vm.nickname = "오열하는 운영체제 및 실험"
//  vm.allowNSFW = false
//  vm.allowPolitical = true
//  
//  return NavigationStack {
//    AraSettingsView(vm: vm)
//  }
//}
//
//#Preview("Error State") {
//  let vm = MockAraSettingsViewModel()
//  vm.state = .error(message: "Network error")
//  
//  return NavigationStack {
//    AraSettingsView(vm: vm)
//  }
//}
