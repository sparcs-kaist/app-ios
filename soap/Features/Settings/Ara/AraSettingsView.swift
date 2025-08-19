//
//  AraSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct AraSettingsView: View {
  @Binding var vm: SettingsViewModelProtocol
  @State private var showNicknameAlert: Bool = false
  
  var body: some View {
    List {
      Section(header: Text("Profile")) {
        TextField("Nickname", text: $vm.araNickname)
        .autocorrectionDisabled()
        .onSubmit {
          updateAraNickname()
        }
      }

      Section(header: Text("Posts")) {
        Toggle("Allow NSFW", isOn: $vm.araAllowNSFWPosts)
        Toggle("Allow Political", isOn: $vm.araAllowPoliticalPosts)
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
    .alert("Error", isPresented: $showNicknameAlert) {
      
    } message: {
      Text("Nicknames can only be changed every 3 months. Please try again later.")
    }
  }
  
  func updateAraNickname() {
    Task {
      do {
        try await vm.updateAraNickname()
      } catch {
        if let error = error as? SettingsViewModel.SettingsError, error == .araNicknameInterval {
          showNicknameAlert = true
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    AraSettingsView(vm: .constant(SettingsViewModel()))
  }
}
