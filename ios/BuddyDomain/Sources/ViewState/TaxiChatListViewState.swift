//
//  TaxiChatListViewState.swift
//  BuddyDomain
//
//  Created by 하정우 on 3/7/26.
//

public enum TaxiChatListViewState: Equatable {
  case loading
  case loaded(onGoing: [TaxiRoom], done: [TaxiRoom])
  case error(message: String)
}
