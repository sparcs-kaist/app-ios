//
//  SettingsView.swift
//  soap
//
//  Created by 하정우 on 7/23/25.
//

import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Miscellaneous")) {
          appSettings
        }
        
        Section(header: Text("Services")) {
          NavigationLink("Ara") { AraSettingsView().navigationTitle("Ara Settings") }
          NavigationLink("Taxi") { TaxiSettingsView().navigationTitle("Taxi Settings") }
          NavigationLink("OTL") { OTLSettingsView().navigationTitle("OTL Settings") }
        }
      }
      .navigationTitle(Text("Settings"))
    }
  }
  
  private var appSettings: some View {
    Button("Change Language", systemImage: "globe") {
      UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
  }
}

#Preview {
  SettingsView()
}
