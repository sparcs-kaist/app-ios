//
//  SettingsView.swift
//  soap
//
//  Created by 하정우 on 7/23/25.
//

import SwiftUI
import NukeUI

struct SettingsView: View {
  @State private var vm: SettingsViewModel = .init()
  
  var body: some View {
    NavigationStack {
      List {
        appSettings
        araSettings
        taxiSettings
        otlSettings
      }.navigationTitle(Text("Settings"))
    }
  }
  
  private var appSettings: some View {
    Section(header: Text("App Settings")) {
      Button(action: {
        UIApplication.shared.open(URL(string: "App-prefs:org.sparcs.soap")!)
      }) {
        Text("Change App Language")
      }
    }
  }
  
  private var araSettings: some View {
    Section(header: Text("Ara")) {
      RowElementView(title: "Nickname", content: "오열하는 운영체제 및 실험_2f94d")
      Toggle(isOn: $vm.araAllowSexualPosts) {
        Text("Allow Sexual Posts")
      }
      Toggle(isOn: $vm.araAllowPoliticalPosts) {
        Text("Allow Political Posts")
      }
      NavigationLink {
        AraBlockedUsersView(blockedUsers: vm.araBlockedUsers)
      } label: {
        RowElementView(title: "Blocked Users", content: "\(vm.araBlockedUsers.count)")
      }
    }
  }
  
  private var taxiSettings: some View {
    Section(header: Text("Taxi")) {
      RowElementView(title: "Nickname", content: vm.taxiUser?.nickname ?? "Unknown")
      Picker("Bank", selection: $vm.taxiBankName) {
        ForEach(vm.taxiBankNameList, id: \.self) {
          Text($0)
        }
      }
      RowElementView(title: "Account", content: vm.taxiBankNumber)
    }
  }
  
  private var otlSettings: some View {
    Section(header: Text("OTL")) {
      HStack {
        NavigationLink {
          FavoriteDepartmentView(selectedMajor: vm.otlMajor)
        } label: {
          HStack {
            RowElementView(title: "Major", content: "School of Electrical Engineering")
          }
        }
      }
    }
  }
}

struct RowElementView: View {
  var title: String
  var content: String
  
  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Text(content)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  SettingsView()
}
