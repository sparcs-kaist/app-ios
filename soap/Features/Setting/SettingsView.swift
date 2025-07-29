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
        information
        ara_settings
        taxi_settings
        otlplus_settings
      }.navigationTitle(Text("Settings"))
    }
  }
  
  private var information: some View {
    Section(header: Text("My Information")) {
      HStack {
        Text("Name")
        Spacer()
        Text("John Appleseed")
          .foregroundStyle(.secondary)
      }
      HStack {
        Text("Email")
        Spacer()
        Text(verbatim: "johnappleseed@kaist.ac.kr")
          .foregroundStyle(.secondary)
      }
      HStack {
        Text("Student ID")
        Spacer()
        Text("12345678")
          .foregroundStyle(.secondary)
      }
    }
  }
  
  private var ara_settings: some View {
    Section(header: Text("Ara")) {
      HStack {
        Text("Nickname")
        Spacer()
        Text("오열하는 운영체제 및 실험_2f94d")
          .foregroundStyle(.secondary)
      }
    }
  }
  
  private var taxi_settings: some View {
    Section(header: Text("Taxi")) {
      HStack {
        Text("Nickname")
        Spacer()
        Text("오열하는 운영체제 및 실험_2f94d")
          .foregroundStyle(.secondary)
      }
    }
  }
  
  private var otlplus_settings: some View {
    Section(header: Text("OTL Plus")) {
      HStack {
        NavigationLink {
          FavoriteDepartmentView(selectedMajor: 1)
          .navigationBarTitleDisplayMode(.inline)
        } label: {
          HStack {
            Text("Major")
            Spacer()
            Text("School of Electrical Engineering")
              .foregroundStyle(.secondary)
          }
        }
      }
    }
  }
}

#Preview {
  SettingsView()
}
