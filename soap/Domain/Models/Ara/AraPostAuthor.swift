//
//  AraPostAuthor.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostAuthor: Identifiable, Hashable {
  let id: String
  let username: String
  let profile: AraPostAuthorProfile
  let isBlocked: Bool?
}
