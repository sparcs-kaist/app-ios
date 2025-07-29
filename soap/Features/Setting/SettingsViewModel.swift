//
//  SettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 7/29/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class SettingsViewModel {
  // MARK: - Mock data
  // TODO: implement API call & data structures
  var araAllowSexualPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araBlockedUsers: [String] = ["유능한 시조새_0b4c"]
  var otlMajor: Int = 1
}
