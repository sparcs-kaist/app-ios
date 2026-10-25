//
//  BoardSectionsSettingsView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/10/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

/// Chooses the sections above the boards in the Boards tab, as Health's Edit Pinned does: the
/// shown ones first, to drag into order or remove, then everything that can be added, by group.
/// Each change is saved straight away, as elsewhere in Settings, and the Boards tab follows it.
public struct BoardSectionsSettingsView: View {
  @State private var model = BoardSectionsSettingsModel()

  public init() { }

  public var body: some View {
    Group {
      switch model.boardsState {
      case .loading:
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .failed(let message):
        ContentUnavailableView {
          Label(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark")
        } description: {
          Text(message)
        } actions: {
          Button(String(localized: "Try Again", bundle: .module)) {
            Task { await model.loadBoards() }
          }
        }
      case .loaded(let boards, let groups):
        BoardSectionsList(
          sections: Binding(get: { model.sections }, set: { model.sections = $0 }),
          boards: boards,
          groups: groups
        )
      }
    }
    .navigationTitle(String(localized: "Board Sections", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.loadBoards() }
  }
}

/// The boards to choose from, and the sections chosen, saved as they change.
@MainActor
@Observable
final class BoardSectionsSettingsModel {
  enum BoardsState {
    case loading
    case loaded(boards: [AraBoard], groups: [AraBoardGroup])
    case failed(message: String)
  }

  private(set) var boardsState: BoardsState = .loading
  var sections: [BoardListSection] {
    didSet {
      guard sections != oldValue else { return }
      store.save(sections)
      analyticsService?.logEvent(BoardListViewEvent.sectionsEdited(count: sections.count))
    }
  }

  @ObservationIgnored private let store: BoardListSectionStore
  @ObservationIgnored @Injected(\.araBoardUseCase) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(\.analyticsService) private var analyticsService: AnalyticsServiceProtocol?

  init(store: BoardListSectionStore = BoardListSectionStore()) {
    self.store = store
    self.sections = store.load()
  }

  func loadBoards() async {
    guard let araBoardUseCase else { return }
    if case .failed = boardsState { boardsState = .loading }
    do {
      let boards = try await araBoardUseCase.fetchBoards().sorted { $0.id < $1.id }
      let groups = Array(Set(boards.map(\.group))).sorted { $0.id < $1.id }
      boardsState = .loaded(boards: boards, groups: groups)
    } catch {
      boardsState = .failed(message: String(localized: "Failed to load boards.", bundle: .module))
    }
  }
}

/// The shown sections, then what can be added, with a reset to the defaults.
private struct BoardSectionsList: View {
  @Binding var sections: [BoardListSection]
  let boards: [AraBoard]
  let groups: [AraBoardGroup]

  /// Boards that can be read, so their posts can be previewed.
  private var readableBoards: [AraBoard] {
    boards.filter { $0.userReadable != false }
  }

  private var addableHighlights: [BoardListSection] {
    [.trending, .latest].filter { !sections.contains($0) }
  }

  var body: some View {
    List {
      Section {
        ForEach(sections) { section in
          Label(title(of: section), systemImage: symbol(of: section))
        }
        .onMove { sections.move(fromOffsets: $0, toOffset: $1) }
        .onDelete { sections.remove(atOffsets: $0) }
      } header: {
        Text("Shown", bundle: .module)
      } footer: {
        Text("Shown above the boards in the Boards tab, in this order.", bundle: .module)
      }

      if !addableHighlights.isEmpty {
        Section {
          ForEach(addableHighlights) { section in
            addButton(for: section)
          }
        } header: {
          Text("Highlights", bundle: .module)
        }
      }

      ForEach(groups) { group in
        let addable = readableBoards.filter { $0.group.id == group.id && !sections.contains(.board(slug: $0.slug)) }
        if !addable.isEmpty {
          Section {
            ForEach(addable) { board in
              addButton(for: .board(slug: board.slug))
            }
          } header: {
            Text(group.name.localized())
          }
        }
      }

      Section {
        Button(String(localized: "Reset to Default", bundle: .module)) {
          withAnimation { sections = BoardListSection.defaults }
        }
        .disabled(sections == BoardListSection.defaults)
      }
    }
    // Always editing, so the shown sections can be dragged and removed straight away.
    .environment(\.editMode, .constant(.active))
    .animation(.default, value: sections)
  }

  private func addButton(for section: BoardListSection) -> some View {
    Button {
      withAnimation { sections.append(section) }
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "plus.circle.fill")
          .symbolRenderingMode(.palette)
          .foregroundStyle(.white, .green)
          .font(.title3)
        Label(title(of: section), systemImage: symbol(of: section))
      }
    }
    .tint(.primary)
    .accessibilityLabel(Text("Add \(title(of: section))", bundle: .module))
  }

  private func board(for slug: String) -> AraBoard? {
    boards.first { $0.slug == slug }
  }

  private func title(of section: BoardListSection) -> String {
    switch section {
    case .trending: BoardHighlight.trending.title
    case .latest: BoardHighlight.latest(boardIDs: []).title
    case .board(let slug): board(for: slug)?.name.localized() ?? slug
    }
  }

  private func symbol(of section: BoardListSection) -> String {
    switch section {
    case .trending: BoardHighlight.trending.symbol
    case .latest: BoardHighlight.latest(boardIDs: []).symbol
    case .board(let slug):
      slug == AraBoard.marketSlug ? "bag.fill" : board(for: slug)?.group.symbolName ?? "list.clipboard"
    }
  }
}
