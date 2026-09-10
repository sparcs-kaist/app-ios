import Foundation
import BuddyDomain

/// The shared coordinate system for headers, grid lines, and lecture cells.
struct TimetableLayout {
  static let hoursWidth: CGFloat = 16
  static let daysHeight: CGFloat = 16
  static let contentTop: CGFloat = daysHeight + 14
  static let contentLeading: CGFloat = hoursWidth + 8
  static let cellSpacing: CGFloat = 4

  let startMinutes: Int
  let endMinutes: Int

  /// - Parameters:
  ///   - beginTime: An optional custom start of the grid, in minutes from midnight.
  ///   - endTime: An optional custom end of the grid, in minutes from midnight.
  ///
  /// Custom bounds only widen the grid: a class outside of them still expands the
  /// visible range, so nothing is ever clipped out of view.
  init(classes: [LectureClass], activities: [TimetableActivity] = [], placement: TimetablePlacement, beginTime: Int? = nil, endTime: Int? = nil) {
    let validClasses = classes.filter { $0.end > $0.begin }
    let validActivities = activities.filter { $0.duration > 0 }
    let earliest = (validClasses.map(\.begin) + validActivities.map(\.begin)).min()
    let latest = (validClasses.map(\.end) + validActivities.map(\.end)).max()

    startMinutes = ([earliest, beginTime].compactMap { $0 }.min() ?? 540) / 60 * 60 // 9:00 AM

    let classesEnd = latest.map { latest in
      switch placement {
      case .view:
        // Leave breathing room below the final class in the app.
        (latest / 60 + 1) * 60
      case .widget:
        // Fit the final class to the next hour, without adding another hour.
        ((latest + 59) / 60) * 60
      }
    }
    // A custom end is honoured as given, rounded up to a whole hour.
    let customEnd = endTime.map { ($0 + 59) / 60 * 60 }
    let end = [classesEnd, customEnd].compactMap { $0 }.max() ?? 1080 // 6:00 PM
    endMinutes = max(startMinutes + 60, end)
  }

  var hours: Range<Int> { (startMinutes / 60)..<(endMinutes / 60) }

  func offset(at minutes: Int, height: CGFloat) -> CGFloat {
    Self.contentTop + contentHeight(height) * CGFloat(minutes - startMinutes) / CGFloat(endMinutes - startMinutes)
  }

  func cellHeight(for item: LectureItem, height: CGFloat) -> CGFloat {
    max(0, contentHeight(height) * CGFloat(item.lectureClass.duration) / CGFloat(endMinutes - startMinutes) - Self.cellSpacing)
  }

  private func contentHeight(_ height: CGFloat) -> CGFloat {
    max(0, height - Self.contentTop)
  }

  struct Cell: Identifiable {
    let item: LectureItem
    let lane: Int
    let laneCount: Int

    var id: String { item.id }

    func width(in dayWidth: CGFloat) -> CGFloat {
      max(0, (dayWidth - CGFloat(laneCount - 1) * TimetableLayout.cellSpacing) / CGFloat(laneCount))
    }

    func x(in dayWidth: CGFloat) -> CGFloat {
      CGFloat(lane) * (width(in: dayWidth) + TimetableLayout.cellSpacing)
    }
  }

  /// Only conflicting groups split in two. A third simultaneous class shares
  /// the overlap lane rather than creating progressively narrower columns.
  static func cells(for items: [LectureItem]) -> [Cell] {
    let sorted = items.enumerated()
      .filter { $0.element.lectureClass.duration > 0 }
      .sorted {
        let lhs = $0.element.lectureClass.begin
        let rhs = $1.element.lectureClass.begin
        return lhs == rhs ? $0.offset < $1.offset : lhs < rhs
      }
      .map(\.element)

    var groups: [[LectureItem]] = []
    var groupEnd = Int.min
    for item in sorted {
      if item.lectureClass.begin >= groupEnd {
        groups.append([item])
        groupEnd = item.lectureClass.end
      } else {
        groups[groups.count - 1].append(item)
        groupEnd = max(groupEnd, item.lectureClass.end)
      }
    }

    return groups.flatMap { group -> [Cell] in
      var mainLaneEnd = Int.min
      return group.map { item in
        let lane = item.lectureClass.begin >= mainLaneEnd ? 0 : 1
        if lane == 0 {
          mainLaneEnd = item.lectureClass.end
        }
        return Cell(item: item, lane: lane, laneCount: min(group.count, 2))
      }
    }
  }
}
