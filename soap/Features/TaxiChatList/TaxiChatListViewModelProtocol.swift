//
//  TaxiChatListViewModelProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

@MainActor
protocol TaxiChatListViewModelProtocol: Observable {
  // MARK: - ViewModel Properties
  var state: TaxiChatListViewModel.ViewState { get }

  // MARK: - Functions
  func fetchData() async
}
