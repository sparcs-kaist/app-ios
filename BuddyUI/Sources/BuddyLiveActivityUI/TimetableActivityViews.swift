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

/// The Lock Screen and banner presentation.
public struct TimetableActivityLockScreenView: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    Group {
      if presentation.mode == .done {
        TimetableActivityDoneSummary(presentation: presentation, onBlack: false)
      } else if let item = presentation.item {
        VStack(alignment: .leading, spacing: 14) {
          HStack(alignment: .center, spacing: 12) {
            TimetableActivityTitle(item: item, color: presentation.color.fill)
            Spacer(minLength: 8)
            TimetableActivityCountdown(presentation: presentation, size: 30, tint: .primary)
          }
          VStack(alignment: .leading, spacing: 10) {
            TimetableActivityProgressRow(presentation: presentation, tint: presentation.color.fill)
            TimetableActivityNextRow(presentation: presentation, onBlack: false)
          }
        }
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 16)
  }
}

// MARK: - Dynamic Island

/// The class glyph used in the compact leading and minimal presentations. Wrapped in a ring
/// that empties over the class once it has started.
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
    ZStack {
      switch presentation.mode {
      case .upcoming:
        Circle().fill(tint)
        Image(systemName: presentation.symbol)
          .font(.system(size: diameter * 0.44, weight: .semibold))
          .foregroundStyle(.black)
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
        Image(systemName: presentation.symbol)
          .font(.system(size: diameter * 0.38, weight: .semibold))
          .foregroundStyle(tint)
      case .done:
        Image(systemName: "checkmark.circle.fill")
          .resizable()
          .symbolRenderingMode(.palette)
          .foregroundStyle(.black, tint)
      }
    }
    .frame(width: diameter, height: diameter)
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

/// The expanded leading region, beside the camera: the class glyph.
public struct TimetableActivityExpandedLeading: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    TimetableActivityBadge(presentation, diameter: 44)
  }
}

/// The expanded centre region, under the camera: class name and room.
public struct TimetableActivityExpandedCenter: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    VStack(spacing: 1) {
      if presentation.mode == .done {
        Text("Done for today", bundle: .module)
          .font(.headline)
          .foregroundStyle(.white)
      } else if let item = presentation.item {
        Text(item.title)
          .font(.headline)
          .foregroundStyle(.white)
        Text(item.location)
          .font(.subheadline)
          .foregroundStyle(.white.opacity(0.6))
      }
    }
    .lineLimit(1)
  }
}

/// The expanded trailing region: the countdown.
public struct TimetableActivityExpandedTrailing: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    if presentation.mode != .done {
      TimetableActivityCountdown(presentation: presentation, size: 26, tint: presentation.color.onBlack)
        .colorScheme(.dark)
    }
  }
}

/// The expanded bottom region: the class's span and what follows it.
public struct TimetableActivityExpandedBottom: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    Group {
      if presentation.mode == .done {
        TimetableActivityDoneSummary(presentation: presentation, onBlack: true, showsTitle: false)
      } else {
        VStack(alignment: .leading, spacing: 10) {
          TimetableActivityProgressRow(presentation: presentation, tint: presentation.color.onBlack)
          TimetableActivityNextRow(presentation: presentation, onBlack: true)
        }
      }
    }
    .colorScheme(.dark)
    .padding(.top, 6)
  }
}

// MARK: - Building blocks

/// Class name and room, with a Calendar-style colour bar.
private struct TimetableActivityTitle: View {
  let item: TimetableActivityAttributes.Item
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(item.title)
        .font(.headline)
      Text(item.location)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .lineLimit(1)
    .padding(.leading, 12)
    .overlay(alignment: .leading) {
      Capsule()
        .fill(color)
        .frame(width: 4)
    }
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

/// Start and end times either side of a bar that fills over the class.
private struct TimetableActivityProgressRow: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  let presentation: TimetableActivityPresentation
  let tint: Color

  var body: some View {
    if let item = presentation.item {
      HStack(spacing: 10) {
        Text(item.beginDate, format: timeFormat)
        Group {
          if presentation.mode == .inProgress, let frozenDate {
            ProgressView(value: item.fraction(at: frozenDate))
          } else if presentation.mode == .inProgress {
            ProgressView(timerInterval: item.beginDate...max(item.endDate, item.beginDate), countsDown: false) {
              EmptyView()
            } currentValueLabel: {
              EmptyView()
            }
          } else {
            ProgressView(value: 0)
          }
        }
        .progressViewStyle(.linear)
        .tint(tint)
        Text(item.endDate, format: timeFormat)
      }
      .font(.caption.weight(.medium))
      .monospacedDigit()
      .foregroundStyle(.secondary)
    }
  }
}

/// "NEXT ● Calculus  13:00", or a note that this is the last class.
private struct TimetableActivityNextRow: View {
  let presentation: TimetableActivityPresentation
  let onBlack: Bool

  var body: some View {
    HStack(spacing: 6) {
      if let next = presentation.next, let nextColor = presentation.nextColor {
        Text("Next", bundle: .module)
          .font(.caption.weight(.semibold))
          .textCase(.uppercase)
          .foregroundStyle(.secondary)
        Circle()
          .fill(onBlack ? nextColor.onBlack : nextColor.fill)
          .frame(width: 7, height: 7)
          .padding(.leading, 2)
        Text(next.title)
          .font(.footnote.weight(.medium))
          .lineLimit(1)
        Spacer(minLength: 8)
        Text(next.beginDate, format: timeFormat)
          .font(.footnote)
          .monospacedDigit()
          .foregroundStyle(.secondary)
      } else {
        Text("Last class today", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer(minLength: 0)
      }
    }
  }
}

/// Shown for the few minutes between the last class ending and the activity going away.
private struct TimetableActivityDoneSummary: View {
  let presentation: TimetableActivityPresentation
  let onBlack: Bool
  var showsTitle = true

  var body: some View {
    HStack(spacing: 12) {
      if showsTitle {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 34))
          .symbolRenderingMode(.palette)
          .foregroundStyle(.white, .green)
      }
      VStack(alignment: .leading, spacing: 2) {
        if showsTitle {
          Text("Done for today", bundle: .module)
            .font(.headline)
        }
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
      Circle().stroke(tint.opacity(0.3), lineWidth: 2.5)
      Circle()
        .trim(from: 0, to: remaining)
        .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .padding(1.25)
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
