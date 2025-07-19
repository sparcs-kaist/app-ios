//
//  TaxiChatViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI
import Observation
import Factory
import Combine

struct TaxiChatGroupOld: Equatable {
  let chatGroup: [TaxiChat]
  let isMe: Bool
}

@MainActor
@Observable
class TaxiChatViewModel {
  // MARK: - Properties
  var groupedChats: [TaxiChatGroup] = []
  var taxiUser: TaxiUser?
  var fetchedDateSet: Set<Date> = []

  private var cancellables = Set<AnyCancellable>()
  private var isFetching: Bool = false

  // MARK: - Dependencies
  private let taxiChatUseCase: TaxiChatUseCaseProtocol
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol

  // MARK: - Initialiser
  init(room: TaxiRoom) {
    taxiChatUseCase = Container.shared.taxiChatUseCase(room)

    bind()
    Task {
      await fetchTaxiUser()
    }
  }

  private func fetchTaxiUser() async {
    self.taxiUser = await userUseCase.taxiUser
  }

  private func bind() {
    taxiChatUseCase.groupedChatsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] groupedChats in
        guard let self = self else { return }
        self.groupedChats = groupedChats
      }
      .store(in: &cancellables)
  }

  func fetchChats(before date: Date) async {
    if isFetching { return }
    isFetching = true
    defer { isFetching = false }
    
    await taxiChatUseCase.fetchChats(before: date)
  }
}
