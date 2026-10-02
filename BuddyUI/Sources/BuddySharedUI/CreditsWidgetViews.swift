//
//  CreditsWidgetViews.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import WidgetKit
import SwiftUI
import BuddyDomain

/// The Credits widgets' entry, shared by the iPhone and Apple Watch widgets.
public struct CreditsEntry: TimelineEntry, Sendable {
  public let date: Date
  /// What the app last computed; nil until it has once.
  public let snapshot: CreditSummarySnapshot?
  public let signInRequired: Bool

  public init(date: Date, snapshot: CreditSummarySnapshot?, signInRequired: Bool) {
    self.date = date
    self.snapshot = snapshot
    self.signInRequired = signInRequired
  }

  /// Shown in the widget gallery and as the redacted placeholder.
  public static let sample = CreditsEntry(
    date: .now,
    snapshot: CreditSummarySnapshot(gpa: 3.72, earnedCredits: 96, graduationCredits: 138),
    signInRequired: false
  )

  /// The totals to show, or nil when signed out or not computed yet.
  var visibleSnapshot: CreditSummarySnapshot? {
    signInRequired ? nil : snapshot
  }
}

// MARK: - Home Screen

/// Medium: GPA and credits side by side, over the progress towards graduation.
public struct CreditsMediumWidgetView: View {
  let entry: CreditsEntry

  public init(entry: CreditsEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let snapshot = entry.visibleSnapshot {
      VStack(alignment: .leading) {
        HStack(alignment: .firstTextBaseline) {
          CreditsWidgetValue(
            title: String(localized: "GPA", bundle: .module),
            value: Self.formattedGPA(snapshot.gpa),
            total: "4.3",
            alignment: .leading
          )

          Spacer()

          CreditsWidgetValue(
            title: String(localized: "Credits", bundle: .module),
            value: "\(snapshot.earnedCredits)",
            total: "\(snapshot.graduationCredits)",
            alignment: .trailing
          )
        }

        Spacer(minLength: 0)

        CreditsWidgetGauge(earned: snapshot.earnedCredits, total: snapshot.graduationCredits)
      }
    } else {
      CreditsWidgetUnavailableView(signInRequired: entry.signInRequired)
    }
  }

  /// Matches the app: up to two decimals, dropping a trailing zero; a dash with no GPA yet.
  static func formattedGPA(_ gpa: Double?) -> String {
    gpa?.formatted(.number.precision(.fractionLength(1...2))) ?? "–"
  }
}

/// Small: credits towards graduation over its progress bar.
public struct CreditsSmallWidgetView: View {
  let entry: CreditsEntry

  public init(entry: CreditsEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let snapshot = entry.visibleSnapshot {
      VStack(alignment: .leading) {
        CreditsWidgetValue(
          title: String(localized: "Credits", bundle: .module),
          value: "\(snapshot.earnedCredits)",
          total: "\(snapshot.graduationCredits)",
          alignment: .leading,
          valueSize: 40
        )

        Spacer(minLength: 0)

        CreditsWidgetGauge(earned: snapshot.earnedCredits, total: snapshot.graduationCredits)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      CreditsWidgetUnavailableView(signInRequired: entry.signInRequired)
    }
  }
}

// MARK: - Accessory (Lock Screen and watch)

/// Inline: "96/138 Credits" beside a graduation cap.
public struct CreditsInlineWidgetView: View {
  let entry: CreditsEntry

  public init(entry: CreditsEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let snapshot = entry.visibleSnapshot {
      Label(
        String(localized: "\(snapshot.earnedCredits)/\(snapshot.graduationCredits) Credits", bundle: .module),
        systemImage: "graduationcap"
      )
    } else {
      Label(String(localized: "Credits", bundle: .module), systemImage: "graduationcap")
    }
  }
}

/// Circular: a capacity ring towards graduation with the credits in the middle.
public struct CreditsCircularWidgetView: View {
  let entry: CreditsEntry

  public init(entry: CreditsEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let snapshot = entry.visibleSnapshot {
      Gauge(value: CreditsProgress.value(snapshot), in: CreditsProgress.range(snapshot)) {
        Image(systemName: "graduationcap")
      } currentValueLabel: {
        Text("\(snapshot.earnedCredits)")
      }
      .gaugeStyle(.accessoryCircularCapacity)
      .accessibilityLabel(String(localized: "Credits towards graduation", bundle: .module))
      .accessibilityValue(CreditsProgress.accessibilityValue(snapshot))
    } else {
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: "graduationcap")
          .font(.title3)
      }
      .accessibilityLabel(String(localized: "Credits", bundle: .module))
    }
  }
}

/// Rectangular: the app's other rectangular accessories' three rows — a tinted
/// header, the value, and a bar — spread over the widget's full height.
public struct CreditsRectangularWidgetView: View {
  @Environment(\.widgetRenderingMode) private var renderingMode

  let entry: CreditsEntry

  public init(entry: CreditsEntry) {
    self.entry = entry
  }

  public var body: some View {
    let snapshot = entry.visibleSnapshot

    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .center) {
        Image(systemName: "graduationcap")

        Text(String(localized: "Credits", bundle: .module))
          .fontDesign(.rounded)
          .fontWeight(.semibold)
          .lineLimit(1)
      }
      .foregroundStyle(accentColor(for: snapshot))
      .widgetAccentable()

      Spacer(minLength: 0)

      if let snapshot {
        // Just the numbers: the header already says "Credits".
        Text(verbatim: "\(snapshot.earnedCredits)/\(snapshot.graduationCredits)")
          .fontWeight(.semibold)
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Spacer(minLength: 0)

        BuddyLinearGauge(
          progress: CreditsProgress.value(snapshot) / CreditsProgress.range(snapshot).upperBound,
          foregroundColor: accentColor(for: snapshot)
        )
        .frame(height: 8)
        .padding(.top, 4)
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Credits towards graduation", bundle: .module))
        .accessibilityValue(CreditsProgress.accessibilityValue(snapshot))
      } else {
        // Short enough for the one line a rectangular accessory leaves for it.
        Text(entry.signInRequired
          ? String(localized: "Sign in to Buddy", bundle: .module)
          : String(localized: "Open Credits in Buddy", bundle: .module))
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  /// Like the D-Day widget: a colour in full colour (green once the minimum is met),
  /// the primary colour when the face or Lock Screen tints it.
  private func accentColor(for snapshot: CreditSummarySnapshot?) -> Color {
    guard renderingMode == .fullColor else { return .primary }
    guard let snapshot else { return .indigo }
    return snapshot.earnedCredits >= snapshot.graduationCredits ? .green : .indigo
  }
}

#if os(watchOS)
/// Corner (watchOS): a graduation cap in the corner, with a curved capacity gauge
/// along the edge showing the credits between 0 and the minimum.
public struct CreditsCornerWidgetView: View {
  let entry: CreditsEntry

  public init(entry: CreditsEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let snapshot = entry.visibleSnapshot {
      Image(systemName: "graduationcap")
        .font(.title3)
        .widgetAccentable()
        .widgetLabel {
          Gauge(value: CreditsProgress.value(snapshot), in: CreditsProgress.range(snapshot)) {
            Text("CR", bundle: .module)
          } currentValueLabel: {
            Text("\(snapshot.earnedCredits)")
          } minimumValueLabel: {
            Text(verbatim: "0")
          } maximumValueLabel: {
            Text(verbatim: "\(snapshot.graduationCredits)")
          }
        }
        .accessibilityLabel(String(localized: "Credits towards graduation", bundle: .module))
        .accessibilityValue(CreditsProgress.accessibilityValue(snapshot))
    } else {
      Image(systemName: "graduationcap")
        .font(.title3)
        .widgetLabel(String(localized: "Credits", bundle: .module))
    }
  }
}
#endif

// MARK: - Parts

/// Gauge values, clamped so taking more than the minimum shows a full gauge.
private enum CreditsProgress {
  static func range(_ snapshot: CreditSummarySnapshot) -> ClosedRange<Double> {
    0...Double(max(snapshot.graduationCredits, 1))
  }

  static func value(_ snapshot: CreditSummarySnapshot) -> Double {
    min(Double(snapshot.earnedCredits), range(snapshot).upperBound)
  }

  static func accessibilityValue(_ snapshot: CreditSummarySnapshot) -> String {
    String(localized: "\(snapshot.earnedCredits) of \(snapshot.graduationCredits) credits", bundle: .module)
  }
}

/// A title over "value/total", like the app's summary card.
private struct CreditsWidgetValue: View {
  let title: String
  let value: String
  let total: String
  let alignment: HorizontalAlignment
  var valueSize: CGFloat = 32

  var body: some View {
    VStack(alignment: alignment, spacing: 2) {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(value)
          .font(.system(size: valueSize, weight: .bold, design: .rounded))
          .minimumScaleFactor(0.6)
          .lineLimit(1)
        Text(verbatim: "/\(total)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

/// Progress towards the graduation minimum; full and green once it's met.
private struct CreditsWidgetGauge: View {
  let earned: Int
  let total: Int

  var body: some View {
    let progress = total > 0 ? min(Double(earned) / Double(total), 1) : 0

    BuddyLinearGauge(progress: progress, foregroundColor: earned >= total ? .green : .accentColor)
      .frame(height: 14)
      .accessibilityElement()
      .accessibilityLabel(String(localized: "Credits towards graduation", bundle: .module))
      .accessibilityValue(String(localized: "\(earned) of \(total) credits", bundle: .module))
  }
}

/// Signed out, or signed in but Credits hasn't been opened yet to compute the totals.
private struct CreditsWidgetUnavailableView: View {
  let signInRequired: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Image(systemName: "graduationcap")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(Self.message(signInRequired: signInRequired))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  static func message(signInRequired: Bool) -> String {
    signInRequired
      ? String(localized: "Sign in to Buddy to see your credits.", bundle: .module)
      : String(localized: "Open Credits in Buddy to calculate your GPA and credits.", bundle: .module)
  }
}
