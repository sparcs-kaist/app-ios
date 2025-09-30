//
//  CourseRepresentable.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import Foundation

protocol CourseRepresentable {
  var credit: Int { get }
  var creditAu: Int { get }
  var grade: Double { get }
  var load: Double { get }
  var speech: Double { get }
}

extension CourseRepresentable {
  private func calculateWeightedAverage(for value: Double) -> Double {
    let numerator = value * Double(credit + creditAu)
    let denominator = credit + creditAu

    return denominator > 0 ? numerator / Double(denominator) : 0.0
  }

  // safely get letter grade string
  private func letter(for value: Double) -> String {
    let index = Int(round(value))
    return Timetable.letters[safe: index] ?? "?"
  }

  // Letter grade for the grade
  var gradeLetter: String {
    letter(for: calculateWeightedAverage(for: grade))
  }

  // Letter grade for the load
  var loadLetter: String {
    letter(for: calculateWeightedAverage(for: load))
  }

  // Letter grade for the speech
  var speechLetter: String {
    letter(for: calculateWeightedAverage(for: speech))
  }
}
