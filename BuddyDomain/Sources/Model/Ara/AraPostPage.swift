//
//  AraPostPage.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

public struct AraPostPage: Sendable {
  public let pages: Int
  public let items: Int
  public let currentPage: Int
  public let results: [AraPost]

  public init(pages: Int, items: Int, currentPage: Int, results: [AraPost]) {
    self.pages = pages
    self.items = items
    self.currentPage = currentPage
    self.results = results
  }
}
