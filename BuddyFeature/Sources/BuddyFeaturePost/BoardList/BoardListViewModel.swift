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
public protocol BoardListViewModelProtocol: Observable {
  var state: BoardListViewModel.ViewState { get }

  func fetchBoards() async
}

@MainActor
@Observable
public class BoardListViewModel: BoardListViewModelProtocol {
  public enum ViewState: Equatable {
    case loading
    case loaded(boards: [AraBoard], groups: [AraBoardGroup])
    case error(message: String)
  }

  // MARK: - Properties
  public var state: ViewState = .loading
  var boards: [AraBoard] = []
  var groups: [AraBoardGroup] = []

  public init() { }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol?

  public func fetchBoards() async {
    guard let araBoardRepository else { return }
    
    do {
      let boards = try await araBoardRepository.fetchBoards()

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
