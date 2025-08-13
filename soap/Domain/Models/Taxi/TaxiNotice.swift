//
//  TaxiNotice.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation

struct TaxiNotice: Identifiable {
  let id: String
  let title: String
  let notionURL: URL
  let isPinned: Bool
  let isActive: Bool
  let createdAt: Date
  let updatedAt: Date
}
