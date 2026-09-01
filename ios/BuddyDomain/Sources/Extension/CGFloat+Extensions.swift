//
//  CGFloat+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 24/06/2025.
//

import Foundation
import UIKit

#if os(iOS)

public extension CGFloat {
  @MainActor
  static var screenWidth: CGFloat {
    UIScreen.main.bounds.width
  }
}

#endif

