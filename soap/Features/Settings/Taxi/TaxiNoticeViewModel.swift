//
//  TaxiNoticeViewModel.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation
import Factory

@MainActor
protocol TaxiNoticeViewModelProtocol: Observable {
  var notices: [TaxiNotice] { get }
  var state: TaxiNoticeViewModel.ViewState { get }
  
  func fetchNotices() async
}

@MainActor
class TaxiNoticeViewModel: TaxiNoticeViewModelProtocol, Observable {
  enum ViewState {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Properties
  var notices: [TaxiNotice] = []
  var state: ViewState = .loading
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.taxiNoticeRepository) private var taxiNoticeRepository: TaxiNoticeRepositoryProtocol
  
  func fetchNotices() async {
    do {
      notices = try await taxiNoticeRepository.fetchNotice()
      state = .loaded
    } catch {
      logger.debug(error)
      state = .error(message: error.localizedDescription)
    }
  }
}
