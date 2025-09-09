//
//  AraBoard.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation

struct AraBoard: Identifiable, Hashable {
  let id: Int
  let slug: String
  let name: LocalizedString
  let group: AraBoardGroup
  let topics: [AraBoardTopic]?
  let isReadOnly: Bool
  let userReadable: Bool?
  let userWritable: Bool?
}
