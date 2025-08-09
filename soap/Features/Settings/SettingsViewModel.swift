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
class SettingsViewModel: SettingsViewModelProtocol {
  enum ViewState {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Mock data
  // TODO: implement API call & data structures
  var araAllowNSFWPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araBlockedUsers: [String] = ["유능한 시조새_0b4c"]
  var taxiBankName: String? {
    get {
      if let name = taxiUser?.account.split(separator: " ").first {
        return String(name)
      } else {
        return nil
      }
    } set {
      // TODO: change 'account' property to variable
    }
  }
  var taxiBankNumber: String {
    get {
      String(taxiUser?.account.split(separator: " ").last ?? "")
    } set {
      // TODO: change 'account' property to variable
    }
  }
  var otlMajor: String = "School of Computer Science"
  let otlMajorList: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
  
  // MARK: - Properties
  var taxiUser: TaxiUser?
  var taxiState: ViewState = .loading
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  
  // MARK: - Functions
  func fetchTaxiUser() async {
    self.taxiUser = await userUseCase.taxiUser
    taxiState = .loaded
  }
}
