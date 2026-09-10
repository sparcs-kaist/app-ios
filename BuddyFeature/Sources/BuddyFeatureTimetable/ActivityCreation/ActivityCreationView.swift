//
//  ActivityCreationView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/9/26.
//

import SwiftUI
import BuddyDomain
import TimetableUI

struct ActivityCreationView: View {
  private enum TimeField { case begin, end }

  let timetable: Timetable?
  let timetableTitle: String
  let occupiedTimes: [TimetableTimeSelection]

  @State private var title = ""
  @State private var location = ""
  @State private var time = TimetableTimeSelection(day: .todayWeekday, begin: 9 * 60, end: 10 * 60)
  @State private var expandedField: TimeField?
  @State private var showTimetable = false
  @Environment(\.dismiss) private var dismiss

  init(timetable: Timetable? = nil, timetableTitle: String = "", occupiedTimes: [TimetableTimeSelection] = []) {
    self.timetable = timetable
    self.timetableTitle = timetableTitle
    self.occupiedTimes = occupiedTimes
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField(String(localized: "Title", bundle: .module), text: $title)
          TextField(String(localized: "Location", bundle: .module), text: $location)
        }

        Section {
          Picker(String(localized: "Day", bundle: .module), selection: dayBinding) {
            ForEach(DayType.allCases.sorted()) { day in
              Text(day.stringValue).tag(day)
            }
          }
          QuarterHourTimeRow(
            String(localized: "Starts", bundle: .module),
            minutes: beginBinding,
            isExpanded: isExpanded(.begin)
          )
          QuarterHourTimeRow(
            String(localized: "Ends", bundle: .module),
            minutes: endBinding,
            isExpanded: isExpanded(.end)
          )
          Button {
            expandedField = nil
            showTimetable = true
          } label: {
            Label(String(localized: "Adjust on Timetable", bundle: .module), systemImage: "calendar.badge.clock")
          }
          .disabled(timetable == nil)
          .accessibilityIdentifier("activity.adjustOnTimetable")
        } header: {
          Text("Date", bundle: .module)
        } footer: {
					ActivityTimeConflictView(time: time, timetable: timetable, occupiedTimes: occupiedTimes)
        }
      }
      .navigationTitle(Text("New Activity", bundle: .module))
      .navigationSubtitle(Text(timetableTitle))
      .navigationBarTitleDisplayMode(.inline)
      .scrollEdgeEffectStyle(.soft, for: .top)
      .toolbar {
        if !showTimetable {
          ToolbarItem(placement: .topBarLeading) {
            Button(String(localized: "Close", bundle: .module), systemImage: "xmark", role: .cancel) { dismiss() }
          }
          ToolbarItem(placement: .topBarTrailing) {
            // Creation remains unavailable until activity persistence is specified.
            Button(String(localized: "Add", bundle: .module), systemImage: "plus", role: .confirm) { }
              .disabled(true)
          }
        }
      }
      .navigationDestination(isPresented: $showTimetable) {
        ActivityTimetableCreationView(timetable: timetable, title: title, time: $time, occupiedTimes: occupiedTimes)
      }
    }
  }

  private var dayBinding: Binding<DayType> {
    Binding(get: { time.day }, set: { time = time.moving(to: time.begin, on: $0) })
  }

  private var beginBinding: Binding<Int> {
    Binding(get: { time.begin }, set: { time = time.moving(to: $0, on: time.day) })
  }

  private var endBinding: Binding<Int> {
    Binding(get: { time.end }, set: { time = time.resizingEnd(to: $0) })
  }

  private func isExpanded(_ field: TimeField) -> Binding<Bool> {
    Binding(get: { expandedField == field }, set: { expandedField = $0 ? field : nil })
  }
}

#Preview {
  ActivityCreationView(timetable: .mock, timetableTitle: "My Timetable")
}
