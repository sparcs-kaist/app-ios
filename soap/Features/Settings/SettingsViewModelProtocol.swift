//
//  SettingsViewModelProtocol.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import Foundation

@MainActor
protocol SettingsViewModelProtocol: Observable {
  var taxiUser: TaxiUser? { get }
  var state: SettingsViewModel.ViewState { get }
  var taxiBankName: String? { get set }
  var taxiBankNumber: String { get set }
  var araAllowNSFWPosts: Bool { get set}
  var araAllowPoliticalPosts: Bool { get set }
  var araNickname: String { get set }
  var araNicknameUpdatable: Bool { get }
  var araNicknameUpdatableSince: Date? { get }
  var otlMajor: String { get set }
  
  var araUser: AraMe? { get }
  var otlMajorList: [String] { get }
  
  func fetchAraUser() async
  func updateAraNickname() async throws
  func updateAraPostVisibility() async
  
  func fetchTaxiUser() async
  func taxiEditBankAccount(account: String) async
}
