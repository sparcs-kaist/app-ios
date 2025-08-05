//
//  BoardListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import SwiftUI
import Observation
import Factory

@MainActor
@Observable
class BoardListViewModel {
  enum ViewState {
    case loading
    case loaded(boards: [AraBoard], groups: [AraBoardGroup])
    case error(message: String)
  }

  // MARK: - Properties
  var state: ViewState = .loading
  var boards: [AraBoard] = []
  var groups: [AraBoardGroup] = []

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol

  func fetchBoards() async {
    do {
      let boards = try await araBoardRepository.getBoards()

      let sortedBoards = boards.sorted { $0.id < $1.id }
      let uniqueGroups = Array(Set(sortedBoards.map(\.group))).sorted { $0.id < $1.id }

      self.boards = sortedBoards
      self.groups = uniqueGroups
      state = .loaded(boards: sortedBoards, groups: uniqueGroups)

    } catch {
      state = .error(message: "Failed to load boards.")
    }
  }
}
