//
//  AraSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct AraSettingsView: View {
  @Binding var vm: SettingsViewModelProtocol
  
  var body: some View {
    List {
      Section(header: Text("Profile")) {
        RowElementView(title: "Nickname", content: "오열하는 운영체제 및 실험_2f94d")
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
        await vm.updateAraUser(allowNSFW: vm.araAllowNSFWPosts, allowPolitical: vm.araAllowPoliticalPosts)
      }
    }
  }
}

#Preview {
  NavigationStack {
    AraSettingsView(vm: .constant(SettingsViewModel()))
  }
}
