//
//  PreviewTaxiChatListViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 3/7/26.
//

import Foundation
import BuddyDomain

@MainActor
@Observable
public class PreviewTaxiChatListViewModel: TaxiChatListViewModelProtocol {
  public var state: TaxiChatListViewState
  public var taxiUser: TaxiUser? = .mock
  
  public init(state: TaxiChatListViewState) {
    self.state = state
  }
  
  public func fetchData() async { }
}
