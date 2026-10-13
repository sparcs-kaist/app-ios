//
//  TimetableActivityViews.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 13/10/2026.
//

#if os(iOS)
import SwiftUI

private let timeFormat = Date.FormatStyle.dateTime.hour().minute()

// MARK: - Lock Screen

/// The Lock Screen and banner presentation, laid out like a boarding pass: the class and its
/// countdown on top, then where to go across the full width, so long building names fit.
public struct TimetableActivityLockScreenView: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    Group {
      if presentation.mode == .done {
        TimetableActivityDoneSummary(presentation: presentation)
      } else if let item = presentation.item {
        VStack(alignment: .leading, spacing: 10) {
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
              Text(item.title)
                .font(.headline)
              Text(verbatim: item.timeRange)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            TimetableActivityCountdown(presentation: presentation, size: 32, tint: .primary)
          }

          HStack(spacing: 12) {
            TimetableActivityPlaceBadge(presentation, height: 44)
            TimetableActivityPlace(item: item, roomFont: .title3.weight(.semibold))
            Spacer(minLength: 0)
          }

          if presentation.mode == .inProgress {
            TimetableActivityProgressBar(item: item, tint: presentation.color.fill)
              .padding(.top, 2)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }
}

// MARK: - Dynamic Island

/// Compact leading and minimal: before class, the building to head to; during class, a ring
/// that empties until it ends.
public struct TimetableActivityBadge: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  private let presentation: TimetableActivityPresentation
  private let diameter: CGFloat

  public init(_ presentation: TimetableActivityPresentation, diameter: CGFloat) {
    self.presentation = presentation
    self.diameter = diameter
  }

  public var body: some View {
    let tint = presentation.color.onBlack
    Group {
      switch presentation.mode {
      case .upcoming:
        TimetableActivityPlaceBadge(presentation, height: diameter)
      case .inProgress:
        if let item = presentation.item {
          if let frozenDate {
            TimetableActivityStaticRing(remaining: 1 - item.fraction(at: frozenDate), tint: tint)
          } else {
            ProgressView(timerInterval: item.beginDate...max(item.endDate, item.beginDate), countsDown: true) {
              EmptyView()
            } currentValueLabel: {
              EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(tint)
          }
        }
      case .done:
        Image(systemName: "checkmark.circle.fill")
          .resizable()
          .symbolRenderingMode(.palette)
          .foregroundStyle(.black, tint)
      }
    }
    .frame(minWidth: diameter, minHeight: diameter, maxHeight: diameter)
  }
}

/// Compact trailing: the countdown alone, sized to its digits so the island stays narrow.
public struct TimetableActivityCompactTimer: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    Group {
      if let target = presentation.countdownTarget {
        TimetableActivityTimerText(target: target)
      } else {
        Text("Done", bundle: .module)
      }
    }
    .font(.system(size: 15, weight: .semibold))
    .monospacedDigit()
    .foregroundStyle(presentation.color.onBlack)
  }
}

/// Expanded leading, beside the camera: the building badge.
public struct TimetableActivityExpandedLeading: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    if presentation.mode == .done {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 40))
        .symbolRenderingMode(.palette)
        .foregroundStyle(.white, .green)
    } else {
      TimetableActivityPlaceBadge(presentation, height: 44)
    }
  }
}

/// Expanded trailing, beside the camera: the countdown.
public struct TimetableActivityExpandedTrailing: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    if presentation.mode != .done {
      TimetableActivityCountdown(presentation: presentation, size: 30, tint: presentation.color.onBlack)
        .colorScheme(.dark)
    }
  }
}

/// Expanded bottom: the room under the badge, then the class and its progress.
public struct TimetableActivityExpandedBottom: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    Group {
      if presentation.mode == .done {
        TimetableActivityDoneSummary(presentation: presentation, showsSymbol: false)
      } else if let item = presentation.item {
        VStack(alignment: .leading, spacing: 10) {
          TimetableActivityPlace(item: item, roomFont: .title2.weight(.semibold))
          HStack(alignment: .firstTextBaseline) {
            Text(item.title)
              .font(.subheadline.weight(.medium))
              .lineLimit(1)
            Spacer(minLength: 8)
            Text(verbatim: item.timeRange)
              .font(.subheadline)
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
          if presentation.mode == .inProgress {
            TimetableActivityProgressBar(item: item, tint: presentation.color.onBlack)
          }
        }
      }
    }
    .foregroundStyle(.white)
    .colorScheme(.dark)
  }
}

// MARK: - Building blocks

/// The building code on the class colour, like a line badge on a transit sign. Custom blocks
/// have no building code, so they show a pin instead.
private struct TimetableActivityPlaceBadge: View {
  private let presentation: TimetableActivityPresentation
  private let height: CGFloat

  init(_ presentation: TimetableActivityPresentation, height: CGFloat) {
    self.presentation = presentation
    self.height = height
  }

  var body: some View {
    let code = presentation.item?.buildingCode
    Group {
      if let code, !code.isEmpty {
        Text(verbatim: code)
          .font(.system(size: height * 0.4, weight: .bold))
          .fontWidth(code.count > 3 ? .condensed : .standard)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .padding(.horizontal, height * 0.14)
      } else {
        Image(systemName: presentation.symbol)
          .font(.system(size: height * 0.42, weight: .semibold))
      }
    }
    .foregroundStyle(presentation.color.text)
    .frame(minWidth: height, minHeight: height, maxHeight: height)
    .background(presentation.color.fill, in: .rect(cornerRadius: height * 0.27, style: .continuous))
  }
}

/// "Room 101" over the building's name. Custom blocks show their free-text place alone.
private struct TimetableActivityPlace: View {
  let item: TimetableActivityAttributes.Item
  let roomFont: Font

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      if let room = item.room, !room.isEmpty {
        Text("Room \(room)", bundle: .module)
          .font(roomFont)
        Text(item.displayBuildingName)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Text(item.displayBuildingName)
          .font(roomFont)
      }
    }
    .lineLimit(1)
  }
}

/// "Starts in 12:04" / "Ends in 41:12", right-aligned.
private struct TimetableActivityCountdown: View {
  let presentation: TimetableActivityPresentation
  let size: CGFloat
  let tint: Color

  var body: some View {
    if let target = presentation.countdownTarget {
      VStack(alignment: .trailing, spacing: 0) {
        Group {
          if presentation.mode == .upcoming {
            Text("Starts in", bundle: .module)
          } else {
            Text("Ends in", bundle: .module)
          }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)

        TimetableActivityTimerText(target: target)
          .font(.system(size: size, weight: .semibold))
          .monospacedDigit()
          .foregroundStyle(tint)
      }
    }
  }
}

/// A thin bar that fills over the class.
private struct TimetableActivityProgressBar: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  let item: TimetableActivityAttributes.Item
  let tint: Color

  var body: some View {
    Group {
      if let frozenDate {
        ProgressView(value: item.fraction(at: frozenDate))
      } else {
        ProgressView(timerInterval: item.beginDate...max(item.endDate, item.beginDate), countsDown: false) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
      }
    }
    .progressViewStyle(.linear)
    .tint(tint)
  }
}

/// Shown for the few minutes between the last class ending and the activity going away.
private struct TimetableActivityDoneSummary: View {
  let presentation: TimetableActivityPresentation
  var showsSymbol = true

  var body: some View {
    HStack(spacing: 12) {
      if showsSymbol {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 40))
          .symbolRenderingMode(.palette)
          .foregroundStyle(.white, .green)
      }
      VStack(alignment: .leading, spacing: 2) {
        Text("Done for today", bundle: .module)
          .font(.headline)
        if let item = presentation.item {
          Text("\(item.title) ended at \(item.endDate, format: timeFormat)", bundle: .module)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
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

/// Stand-in for the system's circular timer ring when the clock is frozen.
private struct TimetableActivityStaticRing: View {
  let remaining: Double
  let tint: Color

  var body: some View {
    ZStack {
      Circle().stroke(tint.opacity(0.3), lineWidth: 3)
      Circle()
        .trim(from: 0, to: remaining)
        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .padding(1.5)
  }
}

public extension EnvironmentValues {
  /// Renders timers and progress frozen at this moment instead of live. Only for design
  /// review screenshots; activities on the system always tick live.
  @Entry var timetableActivityFrozenDate: Date? = nil
}

extension TimetableActivityAttributes.Item {
  var timeRange: String {
    "\(beginDate.formatted(timeFormat)) – \(endDate.formatted(timeFormat))"
  }

  func fraction(at date: Date) -> Double {
    guard end > begin else { return 1 }
    return min(max(date.timeIntervalSince(beginDate) / endDate.timeIntervalSince(beginDate), 0), 1)
  }
}
#endif
