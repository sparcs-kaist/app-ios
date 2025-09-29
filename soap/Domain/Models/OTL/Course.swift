//
//  Course.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

struct Course: Identifiable, Equatable, Sendable {
  let id: Int
  let code: String
  let department: Department
  let type: LocalizedString
  let title: LocalizedString
  let summary: String
  let reviewTotalWeight: Double
}
