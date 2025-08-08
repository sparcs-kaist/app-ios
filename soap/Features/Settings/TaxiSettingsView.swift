//
//  TaxiSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct TaxiSettingsView: View {
  @Binding var vm: SettingsViewModel
  
  var body: some View {
    List {
      Section(header: Text("Profile")) {
        RowElementView(title: "Nickname", content: vm.taxiUser?.nickname ?? "Unknown")
      }

      Section {
        HStack(alignment: .top) {
          VStack(alignment: .trailing) {
            Picker("Bank Account", selection: $vm.taxiBankName) {
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
      }
    }
  }
}

#Preview {
  NavigationStack {
    TaxiSettingsView(vm: .constant(SettingsViewModel()))
  }
}
