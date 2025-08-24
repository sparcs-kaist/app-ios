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
      switch vm.state {
      case .loading:
        loadingView
      case .loaded:
        loadedView
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
  
  private var loadingView: some View {
    Group {
      Section(header: Text("Profile")) {
        TextField("Nickname", text: .constant("Unknown"))
      }

      Section(header: Text("Posts")) {
        Toggle("Allow NSFW", isOn: .constant(true))
        Toggle("Allow Political", isOn: .constant(true))
      }
    }
    .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    Group {
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
