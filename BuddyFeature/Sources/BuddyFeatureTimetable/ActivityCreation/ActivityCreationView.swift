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

  /// One of the activity's time ranges, with a stable identity so a range can be
  /// removed while the form is showing it.
  private struct EditableTime: Identifiable {
    let id = UUID()
    var selection: TimetableTimeSelection
  }

  private struct ExpandedField: Equatable {
    let timeID: UUID
    let field: TimeField
  }

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
          times: times.map { .init(day: $0.selection.day, begin: $0.selection.begin, end: $0.selection.end) })
  }

  private var canSave: Bool {
    guard let timetable, onSave != nil, onRefresh != nil else { return false }
    return draft.isValid && !draft.hasConflict(in: timetable, excluding: activity?.id)
  }

  @State private var title = ""
  @State private var location = ""
  @State private var times = [EditableTime(selection: .init(day: .todayWeekday, begin: 9 * 60, end: 10 * 60))]
  @State private var expandedField: ExpandedField?
  /// What the person typed for Quick Fill.
  @State private var activityDescription = ""
  @FocusState private var isDescriptionFocused: Bool
  /// The time range being adjusted on the timetable, if any.
  @State private var adjustingTimeID: UUID?
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
      _times = State(initialValue: activity.times.map {
        EditableTime(selection: .init(day: $0.day, begin: $0.begin, end: $0.end))
      })
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        // Only for new activities: an edited one already has its details.
        if activity == nil, viewModel.canParseDescriptions {
          quickFillSection
        }

        Section {
          TextField(String(localized: "Title", bundle: .module), text: $title)
          TextField(String(localized: "Location", bundle: .module), text: $location)
        } header: {
          Text("Information", bundle: .module)
        }

        ForEach($times) { $time in
          timeSection(time: $time)
        }

        Section {
          Button(String(localized: "Add Time", bundle: .module), systemImage: "plus", action: addTime)
            .accessibilityIdentifier("activity.addTime")
        }
      }
      .disabled(viewModel.isSaving || viewModel.needsRefresh)
      .navigationTitle(Text(activity == nil ? String(localized: "New Activity", bundle: .module) : String(localized: "Edit Activity", bundle: .module)))
      .navigationSubtitle(Text(timetableTitle))
      .navigationBarTitleDisplayMode(.inline)
      .scrollEdgeEffectStyle(.soft, for: .top)
			.scrollDismissesKeyboard(.immediately)
      .toolbar {
        if adjustingTimeID == nil {
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
      .navigationDestination(item: $adjustingTimeID) { id in
        ActivityTimetableCreationView(
          timetable: editingTimetable,
          title: title,
          time: selection(for: id),
          occupiedTimes: otherTimes(than: id)
        )
      }
      .task {
        await viewModel.checkAvailability()
      }
    }
  }

  // MARK: - Times

  private func timeSection(time: Binding<EditableTime>) -> some View {
    let id = time.wrappedValue.id
    let index = times.firstIndex { $0.id == id } ?? 0
    let selection = time.selection
    return Section {
      Picker(String(localized: "Day", bundle: .module), selection: dayBinding(selection)) {
        ForEach(DayType.allCases.sorted()) { day in
          Text(day.description).tag(day)
        }
      }
      QuarterHourTimeRow(
        String(localized: "Starts", bundle: .module),
        minutes: beginBinding(selection),
        isExpanded: isExpanded(.begin, of: id)
      )
      QuarterHourTimeRow(
        String(localized: "Ends", bundle: .module),
        minutes: endBinding(selection),
        isExpanded: isExpanded(.end, of: id)
      )
      Button {
        expandedField = nil
        adjustingTimeID = id
      } label: {
        Label(String(localized: "Adjust on Timetable", bundle: .module), systemImage: "calendar.badge.clock")
      }
      .disabled(timetable == nil)
      .accessibilityIdentifier(index == 0 ? "activity.adjustOnTimetable" : "activity.adjustOnTimetable.\(index)")
      if times.count > 1 {
        Button(role: .destructive) {
          withAnimation {
            if expandedField?.timeID == id { expandedField = nil }
            times.removeAll { $0.id == id }
          }
        } label: {
          // A form draws a button's icon in the accent colour whatever its role.
          Label {
            Text("Remove Time", bundle: .module)
          } icon: {
            Image(systemName: "minus.circle").foregroundStyle(.red)
          }
        }
        .accessibilityIdentifier("activity.removeTime.\(index)")
      }
    } header: {
      if times.count > 1 {
        Text("Time \(index + 1)", bundle: .module)
      } else {
        Text("Date", bundle: .module)
      }
    } footer: {
      ActivityTimeConflictView(time: selection.wrappedValue, timetable: editingTimetable, occupiedTimes: otherTimes(than: id))
    }
  }

  /// A new range at the same time on the day after the last one.
  private func addTime() {
    guard let last = times.last?.selection else { return }
    let days = DayType.allCases.sorted()
    let next = days[((days.firstIndex(of: last.day) ?? 0) + 1) % days.count]
    expandedField = nil
    withAnimation {
      times.append(EditableTime(selection: last.moving(to: last.begin, on: next)))
    }
  }

  /// The activity's other ranges, which one range must not overlap.
  private func otherTimes(than id: UUID) -> [TimetableTimeSelection] {
    times.filter { $0.id != id }.map(\.selection)
  }

  private func selection(for id: UUID) -> Binding<TimetableTimeSelection> {
    Binding(
      get: { times.first { $0.id == id }?.selection ?? .init(day: .todayWeekday, begin: 9 * 60, end: 10 * 60) },
      set: { updated in
        guard let index = times.firstIndex(where: { $0.id == id }) else { return }
        times[index].selection = updated
      }
    )
  }

  // MARK: - Quick Fill

  private var quickFillSection: some View {
    Section {
      HStack {
        TextField(
          String(localized: "Study group on Tuesday 7–9pm at the library", bundle: .module),
          text: $activityDescription
        )
        .focused($isDescriptionFocused)
        .submitLabel(.done)
        .onSubmit(fillFromDescription)
        .onChange(of: activityDescription) { viewModel.clearParseError() }
        .accessibilityIdentifier("activity.quickFill")

        Button(action: fillFromDescription) {
          if viewModel.isParsing {
            ProgressView()
          } else {
            Image(systemName: "wand.and.sparkles")
          }
        }
        .buttonStyle(.borderless)
        .disabled(isDescriptionBlank || viewModel.isParsing)
        .accessibilityLabel(String(localized: "Fill In Details", bundle: .module))
      }
    } header: {
      Text("Quick Fill", bundle: .module)
    } footer: {
      if let message = viewModel.parseErrorMessage {
        Text(message)
          .foregroundStyle(.red)
      } else {
        Text("Apple Intelligence fills in the details below, so check them before adding.", bundle: .module)
      }
    }
  }

  private var isDescriptionBlank: Bool {
    activityDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func fillFromDescription() {
    guard !isDescriptionBlank else { return }
    isDescriptionFocused = false
    Task {
      guard let parsed = await viewModel.parse(activityDescription) else { return }
      withAnimation {
        apply(parsed)
      }
    }
  }

  /// Fills in what the description gave, leaving the rest as it was. Several
  /// days or several times, as in "every day at 22:00" or "수요일 아침 7시,
  /// 저녁 9시", become a time for each day at each hour; otherwise the
  /// description's time goes into the first range.
  private func apply(_ parsed: ParsedActivity) {
    if let parsedTitle = parsed.title { title = parsedTitle }
    if let parsedLocation = parsed.location { location = parsedLocation }
    guard let time = times.first?.selection else { return }
    let first = ParsedActivity.Time(begin: parsed.begin ?? time.begin, end: parsed.end)
    let hours = [first] + parsed.laterTimes
    let days = parsed.days.isEmpty ? [time.day] : parsed.days
    // A start with no end keeps the current length, as moving the start does.
    func selection(on day: DayType, at hour: ParsedActivity.Time) -> TimetableTimeSelection {
      TimetableTimeSelection(day: day, begin: hour.begin, end: hour.end ?? hour.begin + time.duration)
    }
    if days.count > 1 || hours.count > 1 {
      times = days.flatMap { day in hours.map { EditableTime(selection: selection(on: day, at: $0)) } }
    } else {
      times[0].selection = selection(on: days[0], at: first)
    }
    expandedField = nil
  }

  private func dayBinding(_ time: Binding<TimetableTimeSelection>) -> Binding<DayType> {
    Binding(get: { time.wrappedValue.day }, set: { time.wrappedValue = time.wrappedValue.moving(to: time.wrappedValue.begin, on: $0) })
  }

  private func beginBinding(_ time: Binding<TimetableTimeSelection>) -> Binding<Int> {
    Binding(get: { time.wrappedValue.begin }, set: { time.wrappedValue = time.wrappedValue.moving(to: $0, on: time.wrappedValue.day) })
  }

  private func endBinding(_ time: Binding<TimetableTimeSelection>) -> Binding<Int> {
    Binding(get: { time.wrappedValue.end }, set: { time.wrappedValue = time.wrappedValue.resizingEnd(to: $0) })
  }

  private func isExpanded(_ field: TimeField, of timeID: UUID) -> Binding<Bool> {
    let expanded = ExpandedField(timeID: timeID, field: field)
    return Binding(get: { expandedField == expanded }, set: { expandedField = $0 ? expanded : nil })
  }
}

#Preview {
  ActivityCreationView(timetable: .mock, timetableTitle: "My Timetable")
}
