//
//  DayTimetableView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// A single day as a one-column timetable grid: every lecture and activity is
/// offset and sized by its time and duration against an hourly ruler. Tapping
/// an entry hands it back so the root can jump to Up Next at it.
struct DayTimetableView: View {
  let timetable: Timetable
  let day: DayType
  let onSelect: (ScheduleEntry) -> Void

  @Environment(\.timetableTheme) private var theme

  private static let hourHeight: CGFloat = 44
  private static let gutterWidth: CGFloat = 16
  private static let blockSpacing: CGFloat = 2

  private var items: [ScheduleEntry] {
    timetable.scheduleEntries(day: day)
  }

  // Hour-aligned bounds that always cover at least 09:00–18:00; entries
  // outside that window only widen the grid, mirroring TimetableLayout.
  private var startMinutes: Int {
    min(540, (items.map { $0.classTime.begin }.min() ?? 540) / 60 * 60)
  }

  private var endMinutes: Int {
    let latest = items.map { $0.classTime.end }.max() ?? 1080
    return max(1080, (latest + 59) / 60 * 60)
  }

  var body: some View {
    if items.isEmpty {
      Text("There is no class on this day.")
        .multilineTextAlignment(.center)
        .navigationTitle(day.description)
    } else {
      ScrollView {
        grid
          .padding(.horizontal, 4)
          .padding(.bottom, 8)
      }
      .navigationTitle(day.description)
    }
  }

  private var grid: some View {
    let height = CGFloat(endMinutes - startMinutes) / 60 * Self.hourHeight

    return HStack(alignment: .top, spacing: 4) {
      timeGutter
        .frame(width: Self.gutterWidth, height: height)

      ZStack(alignment: .topLeading) {
        hourLines
        GeometryReader { geometry in
          ForEach(cells) { cell in
            Button {
              onSelect(cell.entry)
            } label: {
              block(for: cell.entry)
            }
            .buttonStyle(.plain)
            .frame(
              width: cell.width(in: geometry.size.width),
              height: blockHeight(forDuration: cell.entry.classTime.duration)
            )
            .offset(
              x: cell.x(in: geometry.size.width),
              y: offset(at: cell.entry.classTime.begin)
            )
          }
        }
      }
      .frame(height: height)
    }
  }

  private var timeGutter: some View {
    GeometryReader { geometry in
      ForEach(hourMarks, id: \.self) { hour in
        Text("\(hour)")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .frame(width: Self.gutterWidth, alignment: .trailing)
          .offset(y: max(0, offset(at: hour * 60) - 6))
      }
    }
  }

  private var hourLines: some View {
    ForEach(hourMarks, id: \.self) { hour in
      Rectangle()
        .fill(.quaternary)
        .frame(height: 0.5)
        .offset(y: offset(at: hour * 60))
    }
  }

  private var hourMarks: [Int] {
    Array(startMinutes / 60...endMinutes / 60)
  }

  private func block(for entry: ScheduleEntry) -> some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(entry.color(in: theme))
      .overlay(alignment: .topLeading) {
        VStack(alignment: .leading, spacing: 0) {
          Text(entry.title)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(2)
          Text(entry.location)
            .font(.system(size: 9))
            .lineLimit(1)
            .opacity(0.8)
        }
        .foregroundStyle(theme.textColor)
        .padding(4)
      }
  }

  private func offset(at minutes: Int) -> CGFloat {
    CGFloat(minutes - startMinutes) / 60 * Self.hourHeight
  }

  private func blockHeight(forDuration duration: Int) -> CGFloat {
    max(0, CGFloat(duration) / 60 * Self.hourHeight - Self.blockSpacing)
  }

  // Same two-lane conflict handling as TimetableLayout: only overlapping
  // groups split, and a third simultaneous entry shares the overlap lane.
  private struct DayCell: Identifiable {
    let entry: ScheduleEntry
    let lane: Int
    let laneCount: Int

    var id: String { entry.id }

    func width(in dayWidth: CGFloat) -> CGFloat {
      max(0, (dayWidth - CGFloat(laneCount - 1) * 4) / CGFloat(laneCount))
    }

    func x(in dayWidth: CGFloat) -> CGFloat {
      CGFloat(lane) * (width(in: dayWidth) + 4)
    }
  }

  private var cells: [DayCell] {
    var groups: [[ScheduleEntry]] = []
    var groupEnd = Int.min
    for entry in items {
      if entry.classTime.begin >= groupEnd {
        groups.append([entry])
        groupEnd = entry.classTime.end
      } else {
        groups[groups.count - 1].append(entry)
        groupEnd = max(groupEnd, entry.classTime.end)
      }
    }

    return groups.flatMap { group -> [DayCell] in
      var mainLaneEnd = Int.min
      return group.map { entry in
        let lane = entry.classTime.begin >= mainLaneEnd ? 0 : 1
        if lane == 0 {
          mainLaneEnd = entry.classTime.end
        }
        return DayCell(entry: entry, lane: lane, laneCount: min(group.count, 2))
      }
    }
  }
}

#Preview {
  NavigationStack {
    DayTimetableView(timetable: .mockList[0], day: .mon) { _ in }
  }
}
