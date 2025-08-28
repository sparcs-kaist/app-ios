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
  var otlMajor: String { get set }
  var otlMajorList: [String] { get }
  func fetchTaxiUser() async
  func taxiEditBankAccount(account: String) async
}
