//
//  SettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 7/29/25.
//

import Foundation
import SwiftUI
import Factory
import Observation
import Moya

@MainActor
protocol SettingsViewModelProtocol: Observable {
  var otlMajor: String { get set }
  var otlMajorList: [String] { get }
}

@Observable
class SettingsViewModel: SettingsViewModelProtocol {
  // MARK: - Properties
  var otlMajor: String = "School of Computer Science"
  let otlMajorList: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
}
