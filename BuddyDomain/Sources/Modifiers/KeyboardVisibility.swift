//
//  KeyboardVisibility.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import SwiftUI
import Combine

public extension View {

  /// Sets an environment value for keyboardShowing
  /// Access this in any child view with
  /// @Environment(\.keyboardShowing) var keyboardShowing
  func addKeyboardVisibilityToEnvironment() -> some View {
    modifier(KeyboardVisibility())
  }
}

public struct KeyboardShowingEnvironmentKey: EnvironmentKey {
  public static let defaultValue: Bool = false
}

public extension EnvironmentValues {
  var keyboardShowing: Bool {
    get { self[KeyboardShowingEnvironmentKey.self] }
    set { self[KeyboardShowingEnvironmentKey.self] = newValue }
  }
}

public struct KeyboardVisibility: ViewModifier {

#if os(iOS)

  @State public var isKeyboardShowing:Bool = false

  public var keyboardPublisher: AnyPublisher<Bool, Never> {
    Publishers
      .Merge(
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillShowNotification)
          .map { _ in true },
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillHideNotification)
          .map { _ in false })
      .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
      .eraseToAnyPublisher()
  }

  public func body(content: Content) -> some View {
    content
      .environment(\.keyboardShowing, isKeyboardShowing)
      .onReceive(keyboardPublisher) { value in
        isKeyboardShowing = value
      }
  }

#else

  public func body(content: Content) -> some View {
    content
      .environment(\.keyboardShowing, false)
  }

#endif
}
