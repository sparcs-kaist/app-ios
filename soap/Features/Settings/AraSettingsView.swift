//
//  AraSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct AraSettingsView: View {
  @Binding var vm: SettingsViewModel
  
  var body: some View {
    List {
      Section(header: Text("Profile")) {
        RowElementView(title: "Nickname", content: "오열하는 운영체제 및 실험_2f94d")
      }

      Section(header: Text("Posts")) {
        Toggle("Allow NSFW", isOn: $vm.araAllowNSFWPosts)
        Toggle("Allow Political", isOn: $vm.araAllowPoliticalPosts)
      }

      Section {
        NavigationLink {
          AraBlockedUsersView(blockedUsers: vm.araBlockedUsers)
        } label: {
          RowElementView(title: "Blocked Users", content: "\(vm.araBlockedUsers.count)")
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
