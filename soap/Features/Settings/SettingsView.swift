//
//  SettingsView.swift
//  soap
//
//  Created by 하정우 on 7/23/25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.openURL) private var openURL
  
  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Miscellaneous")) {
          appSettings
        }
        
        Section(header: Text("Services")) {
          NavigationLink("Ara") { AraSettingsView().navigationTitle("Ara Settings") }
          NavigationLink("Taxi") { TaxiSettingsView().navigationTitle("Taxi Settings") }
        }
      }
      .navigationTitle(Text("Settings"))
    }
  }
  
  private var appSettings: some View {
    Group {
      Button("Change Language", systemImage: "globe") {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
      }
      Button("Send Feedback", systemImage: "exclamationmark.bubble") {
        if let url = URL(string: "mailto:app@sparcs.org"), UIApplication.shared.canOpenURL(url) {
          openURL(url)
        }
      }
    }
  }
}

#Preview {
  SettingsView()
}
