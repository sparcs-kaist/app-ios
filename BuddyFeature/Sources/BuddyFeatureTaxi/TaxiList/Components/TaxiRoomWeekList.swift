//
//  TaxiRoomWeekList.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 03/07/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// A single day's worth of taxi rooms, carrying a stable identity for `ForEach`.
private struct TaxiDaySection: Identifiable {
  /// The weekday symbol, unique within a week and used as the scroll target id.
  let id: String
  let day: Date
  let rooms: [TaxiRoom]
}

/// The loaded taxi-room list, filtered by the selected route and grouped by day
/// of the week. Shows an empty-result state when nothing matches.
struct TaxiRoomWeekList: View {
  let week: [Date]
  let source: TaxiLocation?
  let destination: TaxiLocation?
  let emptyDescription: String
  let onSelectRoom: (TaxiRoom) -> Void
  let onCreateRoom: () -> Void
  let onClearSelection: () -> Void

  /// Route-filtered rooms grouped by day, computed once per input change rather
  /// than filtered inline inside `ForEach` on every body evaluation.
  private let sections: [TaxiDaySection]
  /// Whether any room matched the selected route, independent of day grouping.
  private let hasMatchingRooms: Bool

  init(
    rooms: [TaxiRoom],
    week: [Date],
    source: TaxiLocation?,
    destination: TaxiLocation?,
    emptyDescription: String,
    onSelectRoom: @escaping (TaxiRoom) -> Void,
    onCreateRoom: @escaping () -> Void,
    onClearSelection: @escaping () -> Void
  ) {
    self.week = week
    self.source = source
    self.destination = destination
    self.emptyDescription = emptyDescription
    self.onSelectRoom = onSelectRoom
    self.onCreateRoom = onCreateRoom
    self.onClearSelection = onClearSelection

    let calendar = Calendar.current
    let filteredRooms: [TaxiRoom] = rooms.filter { room in
      let matchesSource = source == nil || room.source.id == source?.id
      let matchesDestination = destination == nil || room.destination.id == destination?.id
      return matchesSource && matchesDestination
    }

    self.hasMatchingRooms = !filteredRooms.isEmpty
    self.sections = week.compactMap { day in
      let roomsForDay = filteredRooms.filter { calendar.isDate($0.departAt, inSameDayAs: day) }
      guard !roomsForDay.isEmpty else { return nil }
      return TaxiDaySection(id: day.weekdaySymbol, day: day, rooms: roomsForDay)
    }
  }

  var body: some View {
    Group {
      if !hasMatchingRooms {
        emptyResult
      } else {
        ForEach(sections) { section in
          VStack(spacing: 12) {
            HStack(alignment: .bottom) {
              Text(section.day.weekdaySymbol)
                .font(.title3)
                .fontWeight(.bold)
              Spacer()
            }
            .padding(.horizontal)

            ForEach(section.rooms) { room in
              TaxiRoomCell(room: room, withOutBackground: false)
                .padding(.horizontal)
                .onTapGesture {
                  onSelectRoom(room)
                }
            }
          }
          .id(section.id)
          .scrollTargetLayout()
        }
      }
    }
    .animation(.spring, value: source)
    .animation(.spring, value: destination)
  }

  private var emptyResult: some View {
    ContentUnavailableView(
      label: {
        Label(String(localized: "No Rides Found", bundle: .module), systemImage: "car.2.fill")
      },
      description: {
        Text(emptyDescription)
      },
      actions: {
        Button(String(localized: "Create a New Group", bundle: .module)) {
          onCreateRoom()
        }

        Button(String(localized: "Clear Selection", bundle: .module)) {
          onClearSelection()
        }
      }
    )
  }
}
