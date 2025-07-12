//
//  TaxiListViewModelProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

public protocol TaxiListViewModelProtocol {
  var state: TaxiListViewModel.ViewState { get set }
  func fetchData() async
}
