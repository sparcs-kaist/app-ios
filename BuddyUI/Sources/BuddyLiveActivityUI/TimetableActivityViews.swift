//
//  TimetableActivityViews.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 13/10/2026.
//

#if os(iOS)
import SwiftUI

private let timeFormat = Date.FormatStyle.dateTime.hour().minute()

// One layout everywhere: the room and a status in the class colour, the class name opposite a
// large countdown, then a progress capsule once class has started and, near the end, the next
// class in its own colour. Black background, white text.

// MARK: - Lock Screen

/// The Lock Screen and banner presentation. Set `.activityBackgroundTint(.black)` around it.
public struct TimetableActivityLockScreenView: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline) {
        TimetableActivityPlaceLabel(presentation)
        Spacer(minLength: 12)
        TimetableActivityStatusLabel(presentation)
      }
      TimetableActivityBody(presentation)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }
}

// MARK: - Dynamic Island

/// Expanded leading, beside the camera: the room.
public struct TimetableActivityExpandedLeading: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    TimetableActivityPlaceLabel(presentation)
  }
}

/// Expanded trailing, beside the camera: the status.
public struct TimetableActivityExpandedTrailing: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    TimetableActivityStatusLabel(presentation)
  }
}

/// Expanded bottom: everything under the labels, as on the Lock Screen.
public struct TimetableActivityExpandedBottom: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    TimetableActivityBody(presentation)
  }
}

/// Compact leading and minimal: the building code on the class colour.
public struct TimetableActivityBadge: View {
  private let presentation: TimetableActivityPresentation
  private let diameter: CGFloat

  public init(_ presentation: TimetableActivityPresentation, diameter: CGFloat) {
    self.presentation = presentation
    self.diameter = diameter
  }

  public var body: some View {
    let code = presentation.item?.buildingCode ?? ""
    Group {
      if presentation.mode == .done {
        Image(systemName: "checkmark")
          .font(.system(size: diameter * 0.5, weight: .bold))
      } else if code.isEmpty {
        Image(systemName: presentation.symbol)
          .font(.system(size: diameter * 0.5, weight: .semibold))
      } else {
        Text(verbatim: code)
          .font(.system(size: diameter * 0.6, weight: .medium))
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .padding(.horizontal, diameter * 0.36)
      }
    }
    .foregroundStyle(presentation.color.text)
    .frame(minWidth: diameter, minHeight: diameter, maxHeight: diameter)
    .background(presentation.color.fill, in: .capsule)
  }
}

/// Minimal: a ring that fills over the class, the building code inside. Before class the ring
/// is an empty track, so it starts filling at the moment the class begins.
public struct TimetableActivityMinimal: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  private let presentation: TimetableActivityPresentation
  private let diameter: CGFloat

  public init(_ presentation: TimetableActivityPresentation, diameter: CGFloat) {
    self.presentation = presentation
    self.diameter = diameter
  }

  public var body: some View {
    let tint = presentation.color.onBlack
    let code = presentation.item?.buildingCode ?? ""
    ZStack {
      if presentation.mode == .done {
        Image(systemName: "checkmark")
          .font(.system(size: diameter * 0.45, weight: .bold))
          .foregroundStyle(tint)
      } else {
        ring(tint: tint)
        Group {
          if code.isEmpty {
            Image(systemName: presentation.symbol)
              .font(.system(size: diameter * 0.36, weight: .semibold))
          } else {
            Text(verbatim: code)
              .font(.system(size: diameter * 0.4, weight: .bold))
              .fontWidth(code.count > 2 ? .condensed : .standard)
              .lineLimit(1)
              .minimumScaleFactor(0.5)
              .padding(.horizontal, diameter * 0.2)
          }
        }
        .foregroundStyle(.white)
      }
    }
    .frame(width: diameter, height: diameter)
  }

  @ViewBuilder
  private func ring(tint: Color) -> some View {
    if presentation.mode == .inProgress, let item = presentation.item {
      if let frozenDate {
        TimetableActivityRing(fraction: item.fraction(at: frozenDate), tint: tint)
      } else {
        // The system advances a timer-driven ring on its own, like the Lock Screen bar.
        ProgressView(timerInterval: item.beginDate...max(item.endDate, item.beginDate), countsDown: false) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(tint)
      }
    } else {
      TimetableActivityRing(fraction: 0, tint: tint)
    }
  }
}

/// The ring drawn by hand: the empty track before class, and the frozen design sheet.
private struct TimetableActivityRing: View {
  let fraction: Double
  let tint: Color

  var body: some View {
    ZStack {
      Circle().stroke(tint.opacity(0.3), lineWidth: 3)
      Circle()
        .trim(from: 0, to: fraction)
        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .padding(1.5)
  }
}

/// Compact trailing: the countdown alone.
public struct TimetableActivityCompactTimer: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    Group {
      if let target = presentation.countdownTarget {
        // A live timer takes every point it's offered, which widens the island until the status
        // bar disappears; pin it to its digits ("19:56" or "1:15:00").
        TimetableActivityTimerText(target: target)
          .multilineTextAlignment(.trailing)
          .frame(width: target.timeIntervalSinceNow >= 3600 ? 66 : 48, alignment: .trailing)
      } else {
        Text("Done", bundle: .module)
      }
    }
    .font(.system(size: 17, weight: .medium))
    .monospacedDigit()
    .foregroundStyle(presentation.color.onBlack)
  }
}

// MARK: - Rows

/// Top left: "E3 304", in the class colour.
private struct TimetableActivityPlaceLabel: View {
  let presentation: TimetableActivityPresentation

  init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  var body: some View {
    Text(verbatim: presentation.item?.shortPlace ?? "")
      .font(.system(size: 17))
      .foregroundStyle(presentation.color.onBlack)
      .lineLimit(1)
  }
}

/// Top right: what the big number means.
private struct TimetableActivityStatusLabel: View {
  let presentation: TimetableActivityPresentation

  init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  var body: some View {
    Group {
      switch presentation.mode {
      case .upcoming: Text("Starts in", bundle: .module)
      case .inProgress: Text("Ends in", bundle: .module)
      case .done: Text("Finished", bundle: .module)
      }
    }
    .font(.system(size: 17))
    .textCase(.uppercase)
    .foregroundStyle(presentation.color.onBlack)
    .lineLimit(1)
  }
}

/// The class name and countdown, the progress capsule, and the next class near the end.
private struct TimetableActivityBody: View {
  let presentation: TimetableActivityPresentation

  init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  var body: some View {
    // Lock Screen and expanded presentations both stop at 160pt, so the state with the
    // "Up next" pill trades a little size and spacing for it.
    let tight = presentation.showsUpNext
    if let item = presentation.item {
      VStack(alignment: .leading, spacing: tight ? 8 : 14) {
        HStack(alignment: .firstTextBaseline) {
          Text(presentation.mode == .done ? String(localized: "Done for today", bundle: .module) : item.title)
            .font(.system(size: 22))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Spacer(minLength: 12)
          Group {
            if let target = presentation.countdownTarget {
              TimetableActivityTimerText(target: target)
            } else {
              Text(item.endDate, format: timeFormat)
            }
          }
          .font(.system(size: tight ? 28 : 38))
          .monospacedDigit()
          .multilineTextAlignment(.trailing)
          .foregroundStyle(.white)
        }

        if presentation.mode == .inProgress {
          TimetableActivityCapsuleBar(item: item, tint: presentation.color.onBlack)
            .frame(height: tight ? 8 : 12)
        }

        if presentation.showsUpNext, let next = presentation.next, let nextColor = presentation.nextColor {
          TimetableActivityUpNext(next: next, color: nextColor.onBlack)
        }
      }
    }
  }
}

// MARK: - Building blocks

/// "UP NEXT | Problem Solving   W3-1 1501", tinted with the next class's colour.
private struct TimetableActivityUpNext: View {
  let next: TimetableActivityAttributes.NextItem
  let color: Color

  var body: some View {
    HStack(spacing: 7) {
      Text("Up next", bundle: .module)
        .fontWeight(.semibold)
        .textCase(.uppercase)
        .fixedSize()
      Rectangle()
        .fill(color.opacity(0.5))
        .frame(width: 1, height: 15)
      Text(next.title)
        .lineLimit(1)
      Spacer(minLength: 6)
      // Where to go matters more than the name, so the name gives way first.
      Text(verbatim: next.shortPlace)
        .fixedSize()
    }
    .font(.system(size: 15))
    .foregroundStyle(color)
    .padding(.horizontal, 14)
    .padding(.vertical, 6)
    .background(color.opacity(0.28), in: .capsule)
  }
}

/// A thick capsule that fills over the class.
private struct TimetableActivityCapsuleBar: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  let item: TimetableActivityAttributes.Item
  let tint: Color

  var body: some View {
    Group {
      if let frozenDate {
        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.18))
            Capsule()
              .fill(tint)
              .frame(width: max(proxy.size.height, proxy.size.width * item.fraction(at: frozenDate)))
          }
        }
      } else {
        // The only bar the system advances on its own; scaled up to the same thickness.
        ProgressView(timerInterval: item.beginDate...max(item.endDate, item.beginDate), countsDown: false) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(tint)
        .scaleEffect(x: 1, y: 3, anchor: .center)
        .clipShape(.capsule)
      }
    }
  }
}

/// A countdown that ticks on its own, sized to its digits.
private struct TimetableActivityTimerText: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  let target: Date

  var body: some View {
    if let frozenDate {
      Text(verbatim: Self.formatted(target.timeIntervalSince(frozenDate)))
    } else {
      Text(.currentDate, format: .timer(countingDownIn: Date.now..<max(target, .now)))
    }
  }

  private static func formatted(_ interval: TimeInterval) -> String {
    let seconds = max(0, Int(interval.rounded()))
    let (hours, minutes, rest) = (seconds / 3600, seconds % 3600 / 60, seconds % 60)
    return hours > 0
      ? String(format: "%d:%02d:%02d", hours, minutes, rest)
      : String(format: "%d:%02d", minutes, rest)
  }
}

public extension EnvironmentValues {
  /// Renders timers and progress frozen at this moment instead of live. Only for design
  /// review screenshots; activities on the system always tick live.
  @Entry var timetableActivityFrozenDate: Date? = nil
}

extension TimetableActivityAttributes.Item {
  func fraction(at date: Date) -> Double {
    guard end > begin else { return 1 }
    return min(max(date.timeIntervalSince(beginDate) / endDate.timeIntervalSince(beginDate), 0), 1)
  }
}
#endif
