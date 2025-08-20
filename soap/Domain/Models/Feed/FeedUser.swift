//
//  FeedUser.swift
//  soap
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import Foundation

struct FeedUser: Identifiable, Hashable {
  let id: String
  let nickname: String
  let profileImageURL: URL?
  let karma: Int
}

