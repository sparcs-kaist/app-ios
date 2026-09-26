//
//  CreditsWidgetViews.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import WidgetKit
import SwiftUI
import BuddyDomain
import BuddySharedUI

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
}

/// Medium: GPA and credits side by side, over the progress towards graduation.
public struct CreditsMediumWidgetView: View {
  let entry: CreditsEntry

  public init(entry: CreditsEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let snapshot = entry.snapshot, !entry.signInRequired {
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
    if let snapshot = entry.snapshot, !entry.signInRequired {
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

      Text(signInRequired
        ? String(localized: "Sign in to Buddy to see your credits.", bundle: .module)
        : String(localized: "Open Credits in Buddy to calculate your GPA and credits.", bundle: .module))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
