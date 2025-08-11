//
//  KeyboardDismissModifier.swift
//  soap
//
//  Created by Soongyu Kwon on 11/08/2025.
//

import SwiftUI

struct KeyboardDismissModifier: ViewModifier {
  let onDismiss: () -> Void

  func body(content: Content) -> some View {
    content
      .onAppear {
        NotificationCenter.default.addObserver(
          forName: UIResponder.keyboardWillHideNotification,
          object: nil, queue: .main
        ) { _ in
          Task { @MainActor in onDismiss() }
        }
      }
      .onDisappear {
        NotificationCenter.default.removeObserver(
          self,
          name: UIResponder.keyboardWillHideNotification,
          object: nil
        )
      }
  }
}

extension View {
  func onKeyboardDismiss(perform action: @escaping () -> Void) -> some View {
    self.modifier(KeyboardDismissModifier(onDismiss: action))
  }
}
