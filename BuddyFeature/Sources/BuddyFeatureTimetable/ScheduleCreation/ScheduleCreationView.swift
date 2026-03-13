//
//  ScheduleCreationView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import SwiftUI
import BuddyDomain

struct ScheduleCreationView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var title: String = ""
  @State private var location: String = ""
  @State private var selectedDay: DayType? = .mon
  @State private var startsAt: Date = Date()
  @State private var endsAt: Date = Date().addingTimeInterval(3600)

  var body: some View {
    NavigationView {
      Form {
        Section {
          TextField("Title", text: $title)
          TextField("Location", text: $location)
        }

        Section {
          Picker("Day", selection: $selectedDay) {
            ForEach(DayType.allCases, id: \.self) { day in
              Text(day.stringValue)
                .tag(day)
            }
          }

        }
      }
      .navigationTitle("New Schedule")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel", systemImage: "xmark", role: .close) {
            dismiss()
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", systemImage: "plus", role: .confirm) {
          }
        }
      }
    }
  }
}


#Preview {
  ScheduleCreationView()
}
