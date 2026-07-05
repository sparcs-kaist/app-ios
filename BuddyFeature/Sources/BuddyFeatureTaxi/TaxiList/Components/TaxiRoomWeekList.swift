//
//  TaxiRoomWeekList.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 03/07/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// The loaded taxi-room list, filtered by the selected route and grouped by day
/// of the week. Shows an empty-result state when nothing matches.
struct TaxiRoomWeekList: View {
  let rooms: [TaxiRoom]
  let week: [Date]
  let source: TaxiLocation?
  let destination: TaxiLocation?
  let emptyDescription: String
  let onSelectRoom: (TaxiRoom) -> Void
  let onCreateRoom: () -> Void
  let onClearSelection: () -> Void

  var body: some View {
    let calendar = Calendar.current
    let filteredRooms: [TaxiRoom] = rooms.filter { room in
      let matchesSource = source == nil || room.source.id == source?.id
      let matchesDestination = destination == nil || room.destination.id == destination?.id
      return matchesSource && matchesDestination
    }

    Group {
      if filteredRooms.isEmpty {
        emptyResult
      } else {
        ForEach(week, id: \.self.weekdaySymbol) { day in
          let roomsForDay = filteredRooms.filter { calendar.isDate($0.departAt, inSameDayAs: day) }
          if !roomsForDay.isEmpty {
            VStack(spacing: 12) {
              HStack(alignment: .bottom) {
                Text(day.weekdaySymbol)
                  .font(.title3)
                  .fontWeight(.bold)
                Spacer()
              }
              .padding(.horizontal)

              ForEach(roomsForDay) { room in
                TaxiRoomCell(room: room, withOutBackground: false)
                  .padding(.horizontal)
                  .id(day.weekdaySymbol)
                  .onTapGesture {
                    onSelectRoom(room)
                  }
              }
            }
            .id(day.weekdaySymbol)
            .scrollTargetLayout()
          }
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
