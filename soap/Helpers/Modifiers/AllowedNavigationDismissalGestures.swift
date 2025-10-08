//
//  AllowedNavigationDismissalGestures.swift
//  soap
//
//  Created by Soongyu Kwon on 08/10/2025.
//

import SwiftUI
import UIKit
import Foundation

// MARK: - AllowedNavigationDismissalGestures

public struct AllowedNavigationDismissalGestures: OptionSet, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let none: AllowedNavigationDismissalGestures = []

  /// Default behaviour
  public static let all: AllowedNavigationDismissalGestures = [.swipeToGoBack, .zoomTransitionGesturesOnly]

  /// Includes both regular left-right swipe to go back and edge-pan for zoom transition dismisall
  public static let edgePanGesturesOnly: AllowedNavigationDismissalGestures = [.swipeToGoBack, .zoomEdgePanToDismiss]

  /// Includes all zoom transition gestures: edge-pan, swipe-down, pinch
  public static let zoomTransitionGesturesOnly: AllowedNavigationDismissalGestures = [.zoomEdgePanToDismiss, .zoomSwipeDownToDismiss, .zoomPinchToDismiss]

  public static let swipeToGoBack = AllowedNavigationDismissalGestures(rawValue: 1 << 0)
  public static let zoomEdgePanToDismiss = AllowedNavigationDismissalGestures(rawValue: 1 << 1)
  public static let zoomSwipeDownToDismiss = AllowedNavigationDismissalGestures(rawValue: 1 << 2)
  public static let zoomPinchToDismiss = AllowedNavigationDismissalGestures(rawValue: 1 << 3)
}

public extension View {
  func navigationAllowDismissalGestures(_ gestures: AllowedNavigationDismissalGestures = .all) -> some View {
    modifier(NavigationAllowedDismissalGesturesModifier(allowedDismissalGestures: gestures))
  }
}

// MARK: - NavigationAllowedDismissalGesturesModifier

private struct NavigationAllowedDismissalGesturesModifier: ViewModifier {
  var allowedDismissalGestures: AllowedNavigationDismissalGestures

  func body(content: Content) -> some View {
    content
      .background(
        NavigationDismissalGestureUpdater(allowedDismissalGestures: allowedDismissalGestures)
          .frame(width: .zero, height: .zero)
      )
  }
}

// MARK: - NavigationDismissalGestureUpdater

private struct NavigationDismissalGestureUpdater: UIViewControllerRepresentable {
  @State private var viewMountRetryCount = 0

  var allowedDismissalGestures: AllowedNavigationDismissalGestures

  func makeUIViewController(context: Context) -> UIViewController { .init() }

  func updateUIViewController(_ viewController: UIViewController, context: Context) {
    Task { @MainActor in
      guard
        let parentVC = viewController.parent,
        let navigationController = parentVC.navigationController
      else {
        // updateUIViewController could get called a bit too early
        // before the view heirarchy has been fully setup
        if viewMountRetryCount < Constants.maxRetryCountForNavigationHeirarchy {
          viewMountRetryCount += 1
          try await Task.sleep(for: .milliseconds(100))
          return updateUIViewController(viewController, context: context)
        } else {
          // unable to find navigation controller
          return
        }
      }

      guard navigationController.topViewController == parentVC else {
        return
      }

      navigationController.interactivePopGestureRecognizer?.isEnabled = allowedDismissalGestures.contains(.swipeToGoBack)

      let viewLevelGestures = parentVC.view.gestureRecognizers ?? []
      for gesture in viewLevelGestures {
        switch String(describing: type(of: gesture)) {
        case Constants.zoomEdgePanToDismissClassType:
          gesture.isEnabled = allowedDismissalGestures.contains(.zoomEdgePanToDismiss)

        case Constants.zoomSwipeDownToDismissClassType:
          gesture.isEnabled = allowedDismissalGestures.contains(.zoomSwipeDownToDismiss)

        case Constants.zoomPinchToDismissClassType:
          gesture.isEnabled = allowedDismissalGestures.contains(.zoomPinchToDismiss)

        default:
          continue
        }
      }
    }
  }

  static func dismantleUIViewController(_ viewController: UIViewController, coordinator: Coordinator) {
    viewController.parent?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    (viewController.parent?.view.gestureRecognizers ?? []).forEach({ gesture in
      if Constants.navigationZoomGestureTypeClasses.contains(String(describing: type(of: gesture))) {
        gesture.isEnabled = true
      }
    })
  }

  // MARK: Private

  private enum Constants {
    static let maxRetryCountForNavigationHeirarchy = 2

    // These are private Navigation related UIKit gesture recognizers that we want to disable
    // when the swipe to go back is disabled.
    static let zoomEdgePanToDismissClassType: String = "_UIParallaxTransitionPanGestureRecognizer" // Edge pan zoom transition dismissal gesture
    static let zoomSwipeDownToDismissClassType: String = {
      // Swipe down to dismiss gesture
      if #available(iOS 26, *) {
        "_UIContentSwipeDismissGestureRecognizer"
      } else {
        "_UISwipeDownGestureRecognizer"
      }
    }()
    static let zoomPinchToDismissClassType: String = "_UITransformGestureRecognizer" // Pinch to dismiss gesture

    static let navigationZoomGestureTypeClasses: Set<String> = [
      zoomEdgePanToDismissClassType,
      zoomSwipeDownToDismissClassType,
      zoomPinchToDismissClassType,
    ]
  }
}
