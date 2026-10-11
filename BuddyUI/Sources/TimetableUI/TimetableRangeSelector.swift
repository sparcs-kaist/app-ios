//
//  TimetableRangeSelector.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 02/10/2026.
//

// Only lecture search on iOS uses it; it has no watchOS client.
#if !os(watchOS)
import SwiftUI
import BuddyDomain

/// The weekday timetable, drawn to fit without scrolling, on which a drag down a day chooses a
/// time range: when classes may meet, for filtering lectures. The timetable's own lectures show
/// faintly underneath, so the range can be fitted around them.
public struct TimetableRangeSelector: View {
  let timetable: Timetable?
  @Binding var filter: LectureTimeFilter
  /// The earliest and latest times that can be chosen, in minutes since midnight.
  let bounds: ClosedRange<Int>
  /// The times a range snaps to, in minutes.
  let step: Int

  /// The range being drawn, shown in place of the filter until the drag ends. Dropped by the
  /// system if the drag is cancelled.
  @GestureState private var draft: LectureTimeFilter?

  private let days = DayType.weekdays

  public init(
    timetable: Timetable?,
    filter: Binding<LectureTimeFilter>,
    bounds: ClosedRange<Int> = LectureTimeFilter.selectableTimes.first!...LectureTimeFilter.selectableTimes.last!,
    step: Int = 30
  ) {
    self.timetable = timetable
    self._filter = filter
    self.bounds = bounds
    self.step = step
  }

  public var body: some View {
    GeometryReader { geometry in
      // The same layout the grid draws with, so the range lines up with its hours and days.
      let layout = TimetableLayout(
        classes: timetable?.lectures.flatMap(\.classes) ?? [],
        activities: timetable?.activities ?? [],
        placement: .view,
        beginTime: bounds.lowerBound,
        endTime: bounds.upperBound
      )
      let columns = Columns(width: geometry.size.width, leadingInset: layout.leadingInset, count: days.count)

      ZStack(alignment: .topLeading) {
        TimetableGrid(
          selectedTimetable: timetable,
          visibleDays: days,
          beginTime: bounds.lowerBound,
          endTime: bounds.upperBound,
          placement: .view
        )
        .opacity(0.45)
        .allowsHitTesting(false)

        selection(layout: layout, columns: columns, height: geometry.size.height)
      }
      .contentShape(.rect)
      .gesture(
        DragGesture(minimumDistance: 0)
          .updating($draft) { value, draft, _ in
            // A sideways swipe, such as going back, leaves the range as it is.
            draft = isAlongDay(value.translation)
              ? range(from: value.startLocation, to: value.location, layout: layout, columns: columns, height: geometry.size.height)
              : nil
          }
          .onEnded { value in
            guard isAlongDay(value.translation) else { return }
            let updated = range(from: value.startLocation, to: value.location, layout: layout, columns: columns, height: geometry.size.height)
            if updated != filter {
              filter = updated
            }
          }
      )
    }
    .sensoryFeedback(.selection, trigger: shown)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("Class Time", bundle: .module))
    .accessibilityValue(Text(accessibilityValue))
    .accessibilityHint(Text("Drag down a day to choose when classes meet.", bundle: .module))
    // The same range, a step at a time: up and down move it, and the actions change its day and
    // length. The first adjustment starts an hour on Monday morning.
    .accessibilityAdjustableAction { direction in
      adjust { $0.moved(by: direction == .increment ? step : -step, within: bounds) }
    }
    .accessibilityAction(named: Text("Previous day", bundle: .module)) {
      adjust { $0.movedDay(by: -1, among: days) }
    }
    .accessibilityAction(named: Text("Next day", bundle: .module)) {
      adjust { $0.movedDay(by: 1, among: days) }
    }
    .accessibilityAction(named: Text("Make Longer", bundle: .module)) {
      adjust { $0.extended(by: step, within: bounds) }
    }
  }

  /// The filter, or the range being drawn.
  private var shown: LectureTimeFilter {
    draft ?? filter
  }

  /// Down or up a day rather than across days; a touch that has not moved counts.
  private func isAlongDay(_ translation: CGSize) -> Bool {
    abs(translation.height) >= abs(translation.width)
  }

  private func adjust(_ change: (Block) -> Block) {
    filter = change(Block(filter: filter, bounds: bounds, step: step, defaultDay: days[0])).filter
  }

  // MARK: - Selection

  /// The chosen range: a block on its day, a band across every day when only times are chosen,
  /// or a whole column when only a day is.
  @ViewBuilder
  private func selection(layout: TimetableLayout, columns: Columns, height: CGFloat) -> some View {
    let filter = shown
    if !filter.isEmpty {
      let begin = filter.begin ?? bounds.lowerBound
      let end = filter.end ?? bounds.upperBound
      let top = layout.offset(at: begin, height: height)
      let blockHeight = max(0, layout.offset(at: end, height: height) - top - TimetableLayout.cellSpacing)
      let x = filter.day.flatMap { days.firstIndex(of: $0) }.map(columns.x) ?? columns.x(0)
      let width = filter.day == nil ? columns.totalWidth : columns.dayWidth

      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 6)
          // Strong enough to cover the lectures under it, so its own times read.
          .fill(Color.accentColor.opacity(0.35))
        RoundedRectangle(cornerRadius: 6)
          .strokeBorder(Color.accentColor, lineWidth: 2)
        if blockHeight > 40 {
          Text(rangeText(begin: begin, end: end))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .lineLimit(2)
            .padding(6)
        }
      }
      .frame(width: width, height: blockHeight)
      .offset(x: x, y: top)
      .allowsHitTesting(false)
      .animation(.snappy(duration: 0.2), value: filter)
    }
  }

  /// Every step the finger has passed over, on the day it went down on.
  private func range(from start: CGPoint, to location: CGPoint, layout: TimetableLayout, columns: Columns, height: CGFloat) -> LectureTimeFilter {
    let first = cellStart(at: start.y, layout: layout, height: height)
    let current = cellStart(at: location.y, layout: layout, height: height)
    let begin = min(first, current)
    let end = min(max(first, current) + step, bounds.upperBound)
    return LectureTimeFilter(day: days[columns.index(at: start.x)], begin: begin, end: end)
  }

  /// The start of the step at `y`, within the bounds.
  private func cellStart(at y: CGFloat, layout: TimetableLayout, height: CGFloat) -> Int {
    let contentHeight = max(1, height - layout.topInset)
    let minutes = Double(layout.startMinutes)
      + Double(y - layout.topInset) / Double(contentHeight) * Double(layout.endMinutes - layout.startMinutes)
    let snapped = Int((minutes / Double(step)).rounded(.down)) * step
    return min(max(snapped, bounds.lowerBound), bounds.upperBound - step)
  }

  private func rangeText(begin: Int, end: Int) -> String {
    "\(Self.clockTime(begin))–\(Self.clockTime(end))"
  }

  private var accessibilityValue: String {
    let filter = shown
    guard !filter.isEmpty else { return String(localized: "Any Time", bundle: .module) }
    let range = rangeText(begin: filter.begin ?? bounds.lowerBound, end: filter.end ?? bounds.upperBound)
    return [filter.day?.description, range].compactMap { $0 }.joined(separator: ", ")
  }

  private static func clockTime(_ minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
  }

  /// A range as VoiceOver adjusts it: always on a day and with both times, within the bounds.
  private struct Block {
    var day: DayType
    var begin: Int
    var end: Int
    let bounds: ClosedRange<Int>
    let step: Int

    init(filter: LectureTimeFilter, bounds: ClosedRange<Int>, step: Int, defaultDay: DayType) {
      self.bounds = bounds
      self.step = step
      day = filter.day ?? defaultDay
      if filter.isEmpty {
        // Nothing chosen yet: an hour from 9:00.
        begin = max(bounds.lowerBound, 9 * 60)
        end = min(begin + 60, bounds.upperBound)
      } else {
        begin = filter.begin ?? bounds.lowerBound
        end = filter.end ?? bounds.upperBound
      }
    }

    var filter: LectureTimeFilter {
      LectureTimeFilter(day: day, begin: begin, end: end)
    }

    func moved(by minutes: Int, within bounds: ClosedRange<Int>) -> Block {
      let length = end - begin
      var block = self
      block.begin = min(max(begin + minutes, bounds.lowerBound), bounds.upperBound - length)
      block.end = block.begin + length
      return block
    }

    func movedDay(by offset: Int, among days: [DayType]) -> Block {
      let index = min(max((days.firstIndex(of: day) ?? 0) + offset, 0), days.count - 1)
      var block = self
      block.day = days[index]
      return block
    }

    /// Longer by `minutes`, or back to a single step once it reaches the end of the day.
    func extended(by minutes: Int, within bounds: ClosedRange<Int>) -> Block {
      var block = self
      block.end = end + minutes <= bounds.upperBound ? end + minutes : begin + step
      return block
    }
  }

  /// The day columns, laid out as `TimetableGrid` lays them out.
  private struct Columns {
    let leadingInset: CGFloat
    let dayWidth: CGFloat
    let count: Int

    init(width: CGFloat, leadingInset: CGFloat, count: Int) {
      self.leadingInset = leadingInset
      self.count = count
      dayWidth = max(0, (width - leadingInset - TimetableLayout.cellSpacing * CGFloat(count - 1)) / CGFloat(count))
    }

    var totalWidth: CGFloat {
      dayWidth * CGFloat(count) + TimetableLayout.cellSpacing * CGFloat(count - 1)
    }

    func x(_ index: Int) -> CGFloat {
      leadingInset + CGFloat(index) * (dayWidth + TimetableLayout.cellSpacing)
    }

    func index(at x: CGFloat) -> Int {
      let index = Int(((x - leadingInset) / (dayWidth + TimetableLayout.cellSpacing)).rounded(.down))
      return min(max(index, 0), count - 1)
    }
  }
}
#endif
