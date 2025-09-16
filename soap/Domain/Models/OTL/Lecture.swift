//
//  Lecture.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

struct Lecture: Identifiable {
  let id: Int
  let course: Int
  let code: String
  let section: String?
  let year: Int
  let semester: SemesterType
  let title: LocalizedString
  let department: Department
  let isEnglish: Bool
  let credit: Int
  let creditAu: Int
  let capacity: Int
  let numberOfPeople: Int
  let grade: Double
  let load: Double
  let speech: Double
  let reviewTotalWeight: Double
  let type: LectureType
  let typeDetail: LocalizedString
  let professors: [Professor]
  let classTimes: [ClassTime]
  let examTimes: [ExamTime]

  // Background colour for TimetableGridCell
  var backgroundColor: Color {
    let index = course % TimetableColorPalette.palettes[0].colors.count
    return TimetableColorPalette.palettes[0].colors[index]
  }

  // Text colour for TimetableGridCell
  var textColor: Color {
    return TimetableColorPalette.palettes[0].textColor
  }
}

extension Lecture {
  private func calculateWeightedAverage(for value: Double, withCredits: Bool = true) -> Double {
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
