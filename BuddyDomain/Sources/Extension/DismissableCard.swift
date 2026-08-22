//
//  DismissableCard.swift
//  BuddyDomain
//
//  `.sheet` becomes an AppKit window-modal sheet on macOS, and AppKit blocks every
//  click outside it — there is no modifier that opts back in. A screen that wants to
//  be dismissable by clicking away therefore cannot be a sheet on the Mac at all; it
//  needs a presentation of its own.
//
//  `dismissableCard` is that presentation, and only on macOS. On iOS it *is*
//  `sheet(item:onDismiss:content:)`, so detents, the drag indicator and
//  swipe-to-dismiss keep behaving exactly as they did.
//

import SwiftUI

// MARK: - Dismiss action

/// How content closes the macOS card.
///
/// The card is not a sheet, so `@Environment(\.dismiss)` cannot close it. Content that
/// dismisses itself — a "Join" button that leaves once the request succeeds, say —
/// would either do nothing or, worse, close whatever real presentation sits above the
/// card. The card publishes this action instead; content reads both and prefers
/// whichever one it was actually given.
public struct BuddyCardDismissAction: Sendable {
  private let action: @MainActor @Sendable () -> Void

  public init(_ action: @escaping @MainActor @Sendable () -> Void) {
    self.action = action
  }

  @MainActor
  public func callAsFunction() {
    action()
  }
}

public extension EnvironmentValues {
  /// Non-nil only inside a macOS ``SwiftUI/View/dismissableCard(item:onDismiss:content:)``.
  /// On iOS it is always nil, which is what makes the fallback to `dismiss()` work.
  @Entry var buddyCardDismiss: BuddyCardDismissAction?
}

// MARK: - Presentation

public extension View {
  /// Presents `content` for `item`, the way `sheet(item:onDismiss:content:)` does.
  ///
  /// On iOS this *is* `sheet(item:onDismiss:content:)` — same arguments, same
  /// behaviour. On macOS it is a dimmed overlay whose scrim dismisses on click, which
  /// a real sheet cannot offer.
  ///
  /// Content should close itself through ``EnvironmentValues/buddyCardDismiss`` when
  /// present, falling back to `dismiss()`, rather than calling `dismiss()` outright.
  @ViewBuilder
  func dismissableCard<Item: Identifiable, Content: View>(
    item: Binding<Item?>,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
  ) -> some View {
    #if os(macOS)
    modifier(DismissableCardModifier(item: item, onDismiss: onDismiss, cardContent: content))
    #else
    sheet(item: item, onDismiss: onDismiss, content: content)
    #endif
  }
}

#if os(macOS)

private struct DismissableCardModifier<Item: Identifiable, CardContent: View>: ViewModifier {
  @Binding var item: Item?
  let onDismiss: (() -> Void)?
  let cardContent: (Item) -> CardContent

  @FocusState private var isCardFocused: Bool

  /// macOS ignores `presentationDetents`, so a sheet there sizes itself to its content
  /// and the card has to state a size outright. This sits between the `.height(400)`
  /// and `.height(500)` detents the call sites ask for on iOS.
  private let cardSize = CGSize(width: 420, height: 460)
  private let cornerRadius: CGFloat = 20

  func body(content: Content) -> some View {
    content
      .overlay {
        if let item {
          card(for: item)
            .transition(.opacity)
        }
      }
      .animation(.smooth(duration: 0.2), value: item != nil)
  }

  private func card(for item: Item) -> some View {
    ZStack {
      // `contentShape` is what makes the scrim swallow clicks. Without it they fall
      // straight through to the list underneath, which selects a different row on the
      // way out and immediately reopens the card.
      Color.black.opacity(0.28)
        .contentShape(.rect)
        .onTapGesture { close() }

      cardContent(item)
        .frame(width: cardSize.width, height: cardSize.height)
        .background(.regularMaterial, in: .rect(cornerRadius: cornerRadius))
        // Content written for a sheet may well ignore the safe area; clipping keeps it
        // from bleeding past the card's corners.
        .clipShape(.rect(cornerRadius: cornerRadius))
        .shadow(radius: 24, y: 8)
        .environment(\.buddyCardDismiss, BuddyCardDismissAction { close() })
    }
    .ignoresSafeArea()
    // A sheet gets Escape from AppKit for free; an overlay does not, so it has to be
    // wired up — and `onExitCommand` only fires on the focused view. The focus ring is
    // suppressed because the card is a container, not a control.
    .focusable()
    .focusEffectDisabled()
    .focused($isCardFocused)
    .onAppear { isCardFocused = true }
    .onExitCommand { close() }
  }

  /// Idempotent: Escape can reach both this and a `.cancelAction` button inside the
  /// content, and `onDismiss` must not run twice when it does.
  private func close() {
    guard item != nil else { return }
    item = nil
    onDismiss?()
  }
}

#endif
