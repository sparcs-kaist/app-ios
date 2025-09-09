//
//  AraPostPage.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostPage: Sendable {
  let pages: Int
  let items: Int
  let currentPage: Int
  let results: [AraPost]
}
