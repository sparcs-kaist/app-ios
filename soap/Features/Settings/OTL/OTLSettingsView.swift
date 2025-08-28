//
//  OTLSettingsView.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

struct OTLSettingsView: View {
  @Binding var vm: OTLSettingsViewModelProtocol
  
  var body: some View {
    List {
      HStack(alignment: .center) {
        Picker("Major", selection: $vm.otlMajor) {
          ForEach(vm.otlMajorList, id: \.self) {
            Text($0)
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    OTLSettingsView(vm: .constant(OTLSettingsViewModel()))
  }
}
