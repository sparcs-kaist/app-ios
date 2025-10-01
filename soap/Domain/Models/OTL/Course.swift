//
//  Course.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

struct Course: Identifiable, Equatable, Sendable, CourseRepresentable {
  let id: Int
  let code: String
  let department: Department
  let type: LocalizedString
  let title: LocalizedString
  let summary: String
  let reviewTotalWeight: Double
  let grade: Double
  let load: Double
  let speech: Double
  let credit: Int
  let creditAu: Int
  let numClasses: Int
  let numLabs: Int
}
