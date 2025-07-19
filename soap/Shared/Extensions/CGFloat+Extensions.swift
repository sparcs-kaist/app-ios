//
//  CGFloat+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 24/06/2025.
//

import Foundation
import UIKit

extension CGFloat {
  @MainActor
  static var screenWidth: CGFloat {
    UIScreen.main.bounds.width
  }

  @MainActor
  static var screenHeight: CGFloat {
    UIScreen.main.bounds.height
  }
}

