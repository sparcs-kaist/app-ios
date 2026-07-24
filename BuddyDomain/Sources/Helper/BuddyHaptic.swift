//
//  BuddyHaptic.swift
//  BuddyDomain
//
//  Replaces the iOS-only Haptica package. On iOS this drives the same UIKit
//  feedback generators Haptica used, so the feel is unchanged; on macOS it maps
//  onto the trackpad feedback patterns AppKit exposes. Lives in BuddyDomain so
//  both BuddyUI and BuddyFeature can reach it.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum BuddyHapticStyle: Sendable {
  case light, medium, heavy, soft, rigid
}

public enum BuddyHaptic: Sendable {
  case impact(BuddyHapticStyle)
  case selection

  // Semantic variants, matching the names the call sites already used.
  case start
  case stop
  case increase
  case decrease
  case success
  case failure
  case warning

  @MainActor
  public func generate() {
    #if os(iOS)
    switch self {
    case .impact(let style):
      let generator = UIImpactFeedbackGenerator(style: style.uiStyle)
      generator.prepare()
      generator.impactOccurred()

    case .selection:
      let generator = UISelectionFeedbackGenerator()
      generator.prepare()
      generator.selectionChanged()

    // Semantic mappings, kept identical to Haptica's own table.
    case .start:    BuddyHaptic.impact(.medium).generate()
    case .stop:     BuddyHaptic.impact(.rigid).generate()
    case .increase: BuddyHaptic.impact(.light).generate()
    case .decrease: BuddyHaptic.impact(.soft).generate()
    case .success:  Self.notify(.success)
    case .failure:  Self.notify(.error)
    case .warning:  Self.notify(.warning)
    }

    #elseif os(macOS)
    // AppKit only offers three patterns, and only on hardware with a Force Touch
    // trackpad — `perform` is a no-op elsewhere.
    let pattern: NSHapticFeedbackManager.FeedbackPattern
    switch self {
    case .impact, .start, .stop:
      pattern = .generic
    case .selection, .increase, .decrease:
      pattern = .alignment
    case .success, .failure, .warning:
      pattern = .levelChange
    }
    NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    #endif
  }

  #if os(iOS)
  @MainActor
  private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(type)
  }
  #endif
}

#if os(iOS)
private extension BuddyHapticStyle {
  var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
    switch self {
    case .light:  .light
    case .medium: .medium
    case .heavy:  .heavy
    case .soft:   .soft
    case .rigid:  .rigid
    }
  }
}
#endif
