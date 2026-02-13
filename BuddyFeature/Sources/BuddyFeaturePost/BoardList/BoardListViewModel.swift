//
//  BoardListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
public class BoardListViewModel: BoardListViewModelProtocol {
  // MARK: - Properties
  public var state: BoardListViewState = .loading
  var boards: [AraBoard] = []
  var groups: [AraBoardGroup] = []

  public init() { }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  public func fetchBoards() async {
    guard let araBoardUseCase else { return }

    do {
      let boards = try await araBoardUseCase.fetchBoards()

      let sortedBoards = boards.sorted { $0.id < $1.id }
      let uniqueGroups = Array(Set(sortedBoards.map(\.group))).sorted { $0.id < $1.id }

      self.boards = sortedBoards
      self.groups = uniqueGroups
      state = .loaded(boards: sortedBoards, groups: uniqueGroups)
      analyticsService?.logEvent(BoardListViewEvent.boardsLoaded)

    } catch {
      state = .error(message: "Failed to load boards.")
    }
  }
}
