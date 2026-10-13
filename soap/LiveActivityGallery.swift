//
//  LiveActivityGallery.swift
//  soap
//
//  Created by Soongyu Kwon on 13/10/2026.
//

#if DEBUG
import SwiftUI
import BuddyDomain
import BuddyLiveActivityUI

/// Design review sheet for the class Live Activity: the real activity views inside frames
/// drawn to the system's measurements (iPhone 17 Pro), for screenshots without a device.
///
/// `xcrun simctl launch booted org.sparcs.soap -LiveActivityGallery lock`
/// (pages: `lock`, `island`, `states`, `statesLight`).
struct LiveActivityGallery: View {
  static var requestedPage: String? { UserDefaults.standard.string(forKey: "LiveActivityGallery") }

  let page: String

  var body: some View {
    Group {
      switch page {
      case "island": IslandPage()
      case "states": StatesPage(scheme: .dark)
      case "statesLight": StatesPage(scheme: .light)
      default: LockScreenPage()
      }
    }
    .ignoresSafeArea()
    .statusBarHidden()
    .persistentSystemOverlays(.hidden)
  }
}

// MARK: - Metrics (logged by chronod for iPhone 17 Pro)

private enum Metrics {
  static let screen = CGSize(width: 402, height: 874)
  static let lockCardWidth: CGFloat = 374
  static let lockCardCorner: CGFloat = 23.5
  static let islandHeight: CGFloat = 36.67
  static let obstructionWidth: CGFloat = 125.33
  static let islandTop: CGFloat = 11
  static let compactInset: CGFloat = 7
  static let expandedWidth: CGFloat = 380
  static let expandedCorner: CGFloat = 46
}

/// A scenario frozen at a moment that puts the class at a realistic time of day.
private struct Sample {
  let presentation: TimetableActivityPresentation
  let date: Date

  init(_ scenario: String) {
    let (hour, minute, second) = switch scenario {
    case "upcoming": (8, 47, 56)
    case "inProgress": (9, 33, 48)
    case "last": (13, 21, 0)
    case "activity": (18, 52, 0)
    default: (14, 17, 0)
    }
    date = Calendar.current.date(bySettingHour: hour, minute: minute, second: second, of: .now)!
    presentation = TimetableActivityPresentation(
      state: LiveActivityDemo.state(for: scenario, now: date)!,
      isStale: false,
      theme: TimetableThemeStore().selectedTheme,
      now: date
    )
  }
}

private extension View {
  func frozen(_ sample: Sample) -> some View {
    environment(\.timetableActivityFrozenDate, sample.date)
  }
}

// MARK: - Frames

/// The Lock Screen platter, with the default system background.
private struct LockScreenCard: View {
  let sample: Sample
  var scheme: ColorScheme = .dark

  var body: some View {
    TimetableActivityLockScreenView(sample.presentation)
      .frame(width: Metrics.lockCardWidth)
      .frame(minHeight: 64)
      .fixedSize(horizontal: false, vertical: true)
      .background(.regularMaterial, in: .rect(cornerRadius: Metrics.lockCardCorner, style: .continuous))
      .environment(\.colorScheme, scheme)
      .frozen(sample)
  }
}

private struct CompactIsland: View {
  let sample: Sample
  private var presentation: TimetableActivityPresentation { sample.presentation }

  var body: some View {
    HStack(spacing: 0) {
      TimetableActivityBadge(presentation, diameter: 22)
        .padding(.leading, Metrics.compactInset)
      Color.clear.frame(width: Metrics.obstructionWidth)
      TimetableActivityCompactTimer(presentation)
        .padding(.trailing, Metrics.compactInset + 3)
    }
    .frame(height: Metrics.islandHeight)
    .background(.black, in: .capsule)
    .environment(\.colorScheme, .dark)
    .frozen(sample)
  }
}

/// Another app's activity takes the main island; ours detaches into the minimal circle.
private struct MinimalIsland: View {
  let sample: Sample
  private var presentation: TimetableActivityPresentation { sample.presentation }

  var body: some View {
    HStack(spacing: 8) {
      HStack(spacing: 0) {
        Image(systemName: "music.note")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(.pink)
          .frame(width: 22)
          .padding(.leading, Metrics.compactInset)
        Color.clear.frame(width: Metrics.obstructionWidth - 20)
        Image(systemName: "waveform")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.pink)
          .padding(.trailing, Metrics.compactInset + 3)
      }
      .frame(height: Metrics.islandHeight)
      .background(.black, in: .capsule)

      TimetableActivityBadge(presentation, diameter: 22)
        .frame(width: Metrics.islandHeight, height: Metrics.islandHeight)
        .background(.black, in: .circle)
    }
    .environment(\.colorScheme, .dark)
    .frozen(sample)
  }
}

/// Expanded regions laid out as the system does: leading and trailing beside the camera,
/// centre under it, bottom across the full width.
private struct ExpandedIsland: View {
  let sample: Sample
  private var presentation: TimetableActivityPresentation { sample.presentation }

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .top) {
        HStack(alignment: .top) {
          TimetableActivityExpandedLeading(presentation)
            .padding(.leading, 4)
          Spacer()
          TimetableActivityExpandedTrailing(presentation)
            .padding(.trailing, 4)
        }
        VStack(spacing: 4) {
          Color.clear.frame(height: Metrics.islandHeight - 8)
          TimetableActivityExpandedCenter(presentation)
        }
        .frame(width: 170)
      }
      TimetableActivityExpandedBottom(presentation)
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, 18)
    .frame(width: Metrics.expandedWidth)
    .background(.black, in: .rect(cornerRadius: Metrics.expandedCorner, style: .continuous))
    .environment(\.colorScheme, .dark)
    .frozen(sample)
  }
}

private struct Wallpaper: View {
  var body: some View {
    LinearGradient(
      colors: [Color(red: 0.10, green: 0.13, blue: 0.32), Color(red: 0.24, green: 0.20, blue: 0.48),
               Color(red: 0.62, green: 0.36, blue: 0.52)],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}

private struct Caption: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.caption.weight(.semibold))
      .textCase(.uppercase)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 18)
  }
}

// MARK: - Pages

private struct LockScreenPage: View {
  var body: some View {
    ZStack(alignment: .top) {
      Wallpaper()

      Capsule()
        .fill(.black)
        .frame(width: Metrics.obstructionWidth, height: Metrics.islandHeight)
        .padding(.top, Metrics.islandTop)

      HStack {
        Text(verbatim: "SKT")
        Spacer()
        Image(systemName: "wifi")
        Image(systemName: "battery.100percent")
      }
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 34)
      .padding(.top, 22)

      VStack(spacing: 0) {
        Image(systemName: "lock.fill")
          .font(.system(size: 16, weight: .semibold))
          .padding(.top, 62)
        Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
          .font(.system(size: 21, weight: .semibold))
          .padding(.top, 10)
        Text(verbatim: "9:41")
          .font(.system(size: 104, weight: .bold, design: .rounded))
          .padding(.top, -6)
        Spacer()
        LockScreenCard(sample: Sample("inProgress"))
          .padding(.bottom, 132)
      }
      .foregroundStyle(.white.opacity(0.92))

      VStack {
        Spacer()
        HStack {
          circleButton("flashlight.off.fill")
          Spacer()
          circleButton("camera.fill")
        }
        .padding(.horizontal, 46)
        Capsule()
          .fill(.white)
          .frame(width: 140, height: 5)
          .padding(.top, 30)
          .padding(.bottom, 8)
      }
    }
    .frame(width: Metrics.screen.width, height: Metrics.screen.height)
  }

  private func circleButton(_ symbol: String) -> some View {
    Image(systemName: symbol)
      .font(.system(size: 20))
      .foregroundStyle(.white)
      .frame(width: 50, height: 50)
      .background(.ultraThinMaterial, in: .circle)
      .environment(\.colorScheme, .dark)
  }
}

private struct IslandPage: View {
  var body: some View {
    VStack(spacing: 14) {
      Caption(text: "Compact · before class")
        .padding(.top, 70)
      CompactIsland(sample: Sample("upcoming"))
      Caption(text: "Compact · in class")
      CompactIsland(sample: Sample("inProgress"))
      Caption(text: "Minimal · beside another app")
      MinimalIsland(sample: Sample("inProgress"))
      Caption(text: "Expanded · before class")
      ExpandedIsland(sample: Sample("upcoming"))
      Caption(text: "Expanded · in class")
      ExpandedIsland(sample: Sample("inProgress"))
      Spacer()
    }
    .frame(width: Metrics.screen.width, height: Metrics.screen.height)
    .background(Color(.systemGroupedBackground))
    .environment(\.colorScheme, .light)
  }
}

private struct StatesPage: View {
  let scheme: ColorScheme

  var body: some View {
    ZStack {
      if scheme == .dark {
        Wallpaper()
      } else {
        LinearGradient(
          colors: [Color(red: 0.98, green: 0.80, blue: 0.62), Color(red: 0.95, green: 0.62, blue: 0.66)],
          startPoint: .top,
          endPoint: .bottom
        )
      }
      VStack(spacing: 10) {
        label("Before class")
          .padding(.top, 54)
        LockScreenCard(sample: Sample("upcoming"), scheme: scheme)
        label("In class")
        LockScreenCard(sample: Sample("inProgress"), scheme: scheme)
        label("Last class of the day")
        LockScreenCard(sample: Sample("last"), scheme: scheme)
        label("Custom block")
        LockScreenCard(sample: Sample("activity"), scheme: scheme)
        label("After the last class")
        LockScreenCard(sample: Sample("done"), scheme: scheme)
        Spacer()
      }
    }
    .frame(width: Metrics.screen.width, height: Metrics.screen.height)
  }

  private func label(_ text: String) -> some View {
    Text(text)
      .font(.caption.weight(.semibold))
      .textCase(.uppercase)
      .foregroundStyle(scheme == .dark ? .white.opacity(0.7) : .black.opacity(0.55))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, 22)
  }
}
#endif
