//
//  TimetableActivityViews.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 13/10/2026.
//

#if os(iOS)
import SwiftUI

private let timeFormat = Date.FormatStyle.dateTime.hour().minute()

// Follows Apple's Live Activity layouts: a label row, one hero line or graphic, a detail row.
// Black background, white text, the class colour as the only accent.

// MARK: - Lock Screen

/// The Lock Screen and banner presentation. Set `.activityBackgroundTint(.black)` around it.
public struct TimetableActivityLockScreenView: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: presentation.mode == .inProgress ? 12 : 4) {
      HStack(alignment: .firstTextBaseline) {
        TimetableActivityLabelLeading(presentation)
        Spacer(minLength: 12)
        TimetableActivityLabelTrailing(presentation)
      }
      TimetableActivityBody(presentation)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 18)
    .environment(\.colorScheme, .dark)
  }
}

// MARK: - Dynamic Island

/// Expanded leading, beside the camera: the left label.
public struct TimetableActivityExpandedLeading: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    TimetableActivityLabelLeading(presentation)
      .environment(\.colorScheme, .dark)
  }
}

/// Expanded trailing, beside the camera: the right label.
public struct TimetableActivityExpandedTrailing: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    TimetableActivityLabelTrailing(presentation)
      .environment(\.colorScheme, .dark)
  }
}

/// Expanded bottom: the same hero and detail rows as the Lock Screen.
public struct TimetableActivityExpandedBottom: View {
  private let presentation: TimetableActivityPresentation

  public init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  public var body: some View {
    TimetableActivityBody(presentation)
      .environment(\.colorScheme, .dark)
  }
}

/// Compact leading and minimal: before class, the building to head to; during it, a ring that
/// empties until it ends.
public struct TimetableActivityBadge: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  private let presentation: TimetableActivityPresentation
  private let diameter: CGFloat

  public init(_ presentation: TimetableActivityPresentation, diameter: CGFloat) {
    self.presentation = presentation
    self.diameter = diameter
  }

  public var body: some View {
    let accent = presentation.color.onBlack
    Group {
      switch presentation.mode {
      case .upcoming:
        if let code = presentation.item?.buildingCode, !code.isEmpty {
          Text(verbatim: code)
            .font(.system(size: diameter * 0.62, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
          Image(systemName: presentation.symbol)
            .font(.system(size: diameter * 0.6, weight: .semibold))
        }
      case .inProgress:
        if let item = presentation.item {
          if let frozenDate {
            TimetableActivityStaticRing(remaining: 1 - item.fraction(at: frozenDate), tint: accent)
          } else {
            ProgressView(timerInterval: item.beginDate...max(item.endDate, item.beginDate), countsDown: true) {
              EmptyView()
            } currentValueLabel: {
              EmptyView()
            }
            .progressViewStyle(.circular)
          }
        }
      case .done:
        Image(systemName: "checkmark")
          .font(.system(size: diameter * 0.6, weight: .bold))
      }
    }
    .foregroundStyle(accent)
    .tint(accent)
    .frame(minWidth: diameter, minHeight: diameter, maxHeight: diameter)
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
        TimetableActivityTimerText(target: target)
      } else {
        Text("Done", bundle: .module)
      }
    }
    .font(.system(size: 15, weight: .semibold, design: .rounded))
    .monospacedDigit()
    .foregroundStyle(presentation.color.onBlack)
  }
}

// MARK: - Rows

/// Top left: the class before it starts, the time left once it has.
private struct TimetableActivityLabelLeading: View {
  let presentation: TimetableActivityPresentation

  init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  var body: some View {
    Group {
      switch presentation.mode {
      case .upcoming:
        Text(presentation.item?.title ?? "")
          .foregroundStyle(.white)
      case .inProgress:
        if let target = presentation.countdownTarget {
          HStack(spacing: 4) {
            Text("Ends in", bundle: .module)
            TimetableActivityTimerText(target: target)
              .monospacedDigit()
          }
          .foregroundStyle(presentation.color.onBlack)
        }
      case .done:
        Text("Done for today", bundle: .module)
          .foregroundStyle(.white)
      }
    }
    .font(.subheadline.weight(.semibold))
    .lineLimit(1)
  }
}

/// Top right: "Starts in", the end time, or a tick.
private struct TimetableActivityLabelTrailing: View {
  let presentation: TimetableActivityPresentation

  init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  var body: some View {
    Group {
      switch presentation.mode {
      case .upcoming:
        Text("Starts in", bundle: .module)
          .foregroundStyle(presentation.color.onBlack)
      case .inProgress:
        if let item = presentation.item {
          Text(item.endDate, format: timeFormat)
            .foregroundStyle(.white)
        }
      case .done:
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      }
    }
    .font(.subheadline.weight(.semibold))
  }
}

/// Below the labels. Before class: where and how long, as large as the flight card's airport
/// codes. During class: a bar filling towards the end. Afterwards: when the day finished.
private struct TimetableActivityBody: View {
  let presentation: TimetableActivityPresentation

  init(_ presentation: TimetableActivityPresentation) {
    self.presentation = presentation
  }

  var body: some View {
    if let item = presentation.item {
      switch presentation.mode {
      case .upcoming:
        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline) {
            Text(verbatim: item.shortPlace)
              .font(.system(size: 32, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.6)
            Spacer(minLength: 12)
            if let target = presentation.countdownTarget {
              TimetableActivityTimerText(target: target)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(presentation.color.onBlack)
            }
          }
          HStack(alignment: .firstTextBaseline) {
            if item.buildingCode != nil {
              Text(item.displayBuildingName)
                .lineLimit(1)
            }
            Spacer(minLength: 12)
            Text(item.beginDate, format: timeFormat)
          }
          .font(.footnote.weight(.medium))
          .foregroundStyle(.secondary)
        }

      case .inProgress:
        VStack(alignment: .leading, spacing: 12) {
          TimetableActivityCapsuleBar(item: item, tint: presentation.color.onBlack)
          HStack(alignment: .firstTextBaseline) {
            Text(item.title)
              .foregroundStyle(.white)
              .lineLimit(1)
            Spacer(minLength: 12)
            Text(verbatim: item.shortPlace)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          .font(.subheadline.weight(.semibold))
        }

      case .done:
        Text("\(item.title) ended at \(item.endDate, format: timeFormat)", bundle: .module)
          .font(.footnote.weight(.medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
  }
}

// MARK: - Building blocks

/// A thick capsule that fills over the class, like the progress tracks in Apple's examples.
private struct TimetableActivityCapsuleBar: View {
  @Environment(\.timetableActivityFrozenDate) private var frozenDate
  let item: TimetableActivityAttributes.Item
  let tint: Color

  var body: some View {
    Group {
      if let frozenDate {
        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            Capsule().fill(tint.opacity(0.25))
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
        .scaleEffect(x: 1, y: 2.6, anchor: .center)
        .clipShape(.capsule)
      }
    }
    .frame(height: 10)
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
  /// "E11 101", the way students say a classroom. Custom blocks use their free-text place.
  var shortPlace: String {
    guard let buildingCode, !buildingCode.isEmpty else { return displayBuildingName }
    return [buildingCode, room].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
  }

  func fraction(at date: Date) -> Double {
    guard end > begin else { return 1 }
    return min(max(date.timeIntervalSince(beginDate) / endDate.timeIntervalSince(beginDate), 0), 1)
  }
}
#endif
