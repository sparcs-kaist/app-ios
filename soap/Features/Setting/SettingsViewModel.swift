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

@MainActor
@Observable
class SettingsViewModel {
  // MARK: - Mock data
  // TODO: implement API call & data structures
  var araAllowSexualPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araBlockedUsers: [String] = ["유능한 시조새_0b4c"]
  var taxiBankName: String = "카카오뱅크"
  var taxiBankNumber: String = "7777-02-3456789"
  var otlMajor: Int = 1
  
  // MARK: - Properties
  var taxiUser: TaxiUser?
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  
  // MARK: - Functions
  func fetchTaxiUser() async {
    self.taxiUser = await userUseCase.taxiUser
  }
}
