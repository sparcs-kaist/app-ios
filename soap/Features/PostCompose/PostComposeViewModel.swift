//
//  PostComposeViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 10/08/2025.
//

import SwiftUI
import Observation
import Factory

@MainActor
protocol PostComposeViewModelProtocol: Observable {
  var board: AraBoard { get }

  var selectedTopic: AraBoardTopic? { get set }
  var title: String { get set }
  var content: String { get set }

  var writeAsAnonymous: Bool { get set }
  var isNSFW: Bool { get set }
  var isPolitical: Bool { get set }
}

@Observable
class PostComposeViewModel: PostComposeViewModelProtocol {
  var board: AraBoard

  var selectedTopic: AraBoardTopic? = nil
  var title: String = ""
  var content: String = ""

  var writeAsAnonymous: Bool = true
  var isNSFW: Bool = false
  var isPolitical: Bool = false

  init(board: AraBoard) {
    self.board = board
  }
}
