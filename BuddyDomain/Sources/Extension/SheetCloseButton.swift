//
//  SheetCloseButton.swift
//  BuddyDomain
//

import SwiftUI

public extension View {
  /// Floats a close button over the top-leading corner of a sheet, on macOS only.
  ///
  /// ``ToolbarItemPlacement/sheetCancellation`` resolves to `.cancellationAction` on
  /// macOS, and AppKit draws that down in the sheet's button bar next to the confirm
  /// button. That is nowhere near where a window's close button lives, so the control
  /// reads as just another action rather than the way out. This puts it where the taxi
  /// room preview already puts its own — same glass circle, same Escape binding.
  ///
  /// Apply this to the sheet's root, outside its `NavigationStack`. The bar holding the
  /// navigation title and the search field is a top safe area inset, so an overlay that
  /// respects it lands a row too low — on the title, or worse, on scrolling content.
  /// The button ignores that inset to sit in the corner of the sheet itself.
  ///
  /// A no-op on iOS: those sheets dismiss by swipe and keep their existing toolbars.
  ///
  /// - Parameter action: What the button and Escape both do.
  @ViewBuilder
  func sheetCloseButton(action: @escaping () -> Void) -> some View {
    #if os(macOS)
    overlay(alignment: .topLeading) {
      Button(String(localized: "Close", bundle: .module), systemImage: "xmark", role: .close, action: action)
        .labelStyle(.iconOnly)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .keyboardShortcut(.cancelAction)
        .padding(12)
        // The button is far too small to reach into the inset on its own — a view only
        // extends into a safe area it actually spans. Give it a frame that fills the
        // sheet first, and the corner it aligns to is the sheet's own.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea(edges: .top)
    }
    #else
    self
    #endif
  }
}
