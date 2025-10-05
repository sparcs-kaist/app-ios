//
//  Course.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

public struct Course: Identifiable, Equatable, Sendable, CourseRepresentable {
  public let id: Int
  public let code: String
  public let department: Department
  public let type: LocalizedString
  public let title: LocalizedString
  public let summary: String
  public let reviewTotalWeight: Double
  public let grade: Double
  public let load: Double
  public let speech: Double
  public let credit: Int
  public let creditAu: Int
  public let numClasses: Int
  public let numLabs: Int

  public init(
    id: Int,
    code: String,
    department: Department,
    type: LocalizedString,
    title: LocalizedString,
    summary: String,
    reviewTotalWeight: Double,
    grade: Double,
    load: Double,
    speech: Double,
    credit: Int,
    creditAu: Int,
    numClasses: Int,
    numLabs: Int
  ) {
    self.id = id
    self.code = code
    self.department = department
    self.type = type
    self.title = title
    self.summary = summary
    self.reviewTotalWeight = reviewTotalWeight
    self.grade = grade
    self.load = load
    self.speech = speech
    self.credit = credit
    self.creditAu = creditAu
    self.numClasses = numClasses
    self.numLabs = numLabs
  }
}
