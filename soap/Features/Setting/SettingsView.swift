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
        Section(header: Text("Settings")) {
          appSettings
        }
        
        Section(header: Text("Services")) {
          NavigationLink("Ara") { araSettings }
          NavigationLink("Taxi") { taxiSettings }
          NavigationLink("OTL") { otlSettings }
        }
      }.navigationTitle(Text("Settings"))
    }.task {
      await vm.fetchTaxiUser()
    }
  }
  
  private var appSettings: some View {
    Button(action: {
      UIApplication.shared.open(URL(string: "App-prefs:org.sparcs.soap")!)
    }) {
      Text("Change App Language")
    }
  }
  
  private var araSettings: some View {
    List {
      rowElementView(title: "Nickname", content: "오열하는 운영체제 및 실험_2f94d")
      Toggle(isOn: $vm.araAllowSexualPosts) {
        Text("Allow Sexual Posts")
      }
      Toggle(isOn: $vm.araAllowPoliticalPosts) {
        Text("Allow Political Posts")
      }
      NavigationLink {
        AraBlockedUsersView(blockedUsers: vm.araBlockedUsers)
      } label: {
        rowElementView(title: "Blocked Users", content: "\(vm.araBlockedUsers.count)")
      }
    }.navigationTitle("Ara Settings")
  }
  
  private var taxiSettings: some View {
    List {
      rowElementView(title: "Nickname", content: vm.taxiUser?.nickname ?? "Unknown")
      HStack(alignment: .top) {
        Text("Bank Account")
        Spacer()
        VStack(alignment: .trailing) {
          Picker("", selection: $vm.taxiBankName) {
            ForEach(Constants.taxiBankNameList, id: \.self) {
              Text($0)
            }
          }
          Spacer()
          TextField("", text: $vm.taxiBankNumber)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.secondary)
        }
      }
    }.navigationTitle("Taxi Settings")
  }
  
  private var otlSettings: some View {
    List {
      HStack {
        NavigationLink {
          FavoriteDepartmentView(selectedMajor: vm.otlMajor)
        } label: {
          HStack {
            rowElementView(title: "Major", content: "School of Electrical Engineering")
          }
        }
      }
    }.navigationTitle("OTL Settings")
  }
  
  func rowElementView(title: String, content: String) -> some View {
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
