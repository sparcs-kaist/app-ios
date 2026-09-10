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
  let activity: TimetableActivity?
  let onSave: ((TimetableActivityDraft) async throws -> Void)?
  let onRefresh: (() async throws -> Void)?
  @State private var viewModel = ActivityCreationViewModel()

  private var editingTimetable: Timetable? {
    guard var timetable else { return nil }
    timetable.activities.removeAll { $0.id == activity?.id }
    return timetable
  }

  private var draft: TimetableActivityDraft {
    .init(title: title.trimmingCharacters(in: .whitespacesAndNewlines), location: location,
          day: time.day, begin: time.begin, end: time.end)
  }

  private var canSave: Bool {
    guard let timetable, onSave != nil, onRefresh != nil else { return false }
    return draft.isValid && !draft.hasConflict(in: timetable, excluding: activity?.id)
  }

  @State private var title = ""
  @State private var location = ""
  @State private var time = TimetableTimeSelection(day: .todayWeekday, begin: 9 * 60, end: 10 * 60)
  @State private var expandedField: TimeField?
  @State private var showTimetable = false
  @Environment(\.dismiss) private var dismiss

  init(timetable: Timetable? = nil, timetableTitle: String = "", activity: TimetableActivity? = nil,
       onSave: ((TimetableActivityDraft) async throws -> Void)? = nil, onRefresh: (() async throws -> Void)? = nil) {
    self.timetable = timetable
    self.timetableTitle = timetableTitle
    self.activity = activity
    self.onSave = onSave
    self.onRefresh = onRefresh
    if let activity {
      _title = State(initialValue: activity.title)
      _location = State(initialValue: activity.location)
      _time = State(initialValue: .init(day: activity.day, begin: activity.begin, end: activity.end))
    }
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
					ActivityTimeConflictView(time: time, timetable: editingTimetable)
        }
      }
      .disabled(viewModel.isSaving || viewModel.needsRefresh)
      .navigationTitle(Text(activity == nil ? String(localized: "New Activity", bundle: .module) : String(localized: "Edit Activity", bundle: .module)))
      .navigationSubtitle(Text(timetableTitle))
      .navigationBarTitleDisplayMode(.inline)
      .scrollEdgeEffectStyle(.soft, for: .top)
      .toolbar {
        if !showTimetable {
          ToolbarItem(placement: .topBarLeading) {
            Button(String(localized: "Close", bundle: .module), systemImage: "xmark", role: .cancel) { dismiss() }
              .disabled(viewModel.isSaving)
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              Task {
                guard let onSave, let onRefresh else { return }
                if await viewModel.save(draft: draft, onSave: onSave, onRefresh: onRefresh) { dismiss() }
              }
            } label: {
              if viewModel.isSaving { ProgressView() }
              else { Text(viewModel.needsRefresh ? String(localized: "Refresh", bundle: .module) : activity == nil ? String(localized: "Add", bundle: .module) : String(localized: "Save", bundle: .module)) }
            }
            .disabled(viewModel.isSaving || (!viewModel.needsRefresh && !canSave))
            .accessibilityIdentifier("activity.save")
          }
        }
      }
      .interactiveDismissDisabled(viewModel.isSaving)
      .alert(String(localized: "Unable to save activity.", bundle: .module), isPresented: Binding(
        get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } }
      )) {
        Button(String(localized: "Okay", bundle: .module), role: .cancel) { viewModel.errorMessage = nil }
      } message: { Text(viewModel.errorMessage ?? "") }
      .navigationDestination(isPresented: $showTimetable) {
        ActivityTimetableCreationView(timetable: editingTimetable, title: title, time: $time)
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
