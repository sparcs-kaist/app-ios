//
//  Timetable.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI

struct Timetable: Identifiable, Comparable, Equatable {
  let id: Int
  var lectures: [Lecture]
  let semester: Semester

  private let defaultMinMinutes = 540 // 9:00 AM
  private let defaultMaxMinutes = 1080 // 6:00 PM

  var letters: [String] = [
    "?",
    "F",
    "F",
    "F",
    "D-",
    "D",
    "D+",
    "C-",
    "C",
    "C+",
    "B-",
    "B",
    "B+",
    "A-",
    "A",
    "A+"
  ]

  // Comparable
  static func < (lhs: Timetable, rhs: Timetable) -> Bool {
    return (lhs.semester == rhs.semester) ? lhs.id < rhs.id : lhs.semester < rhs.semester
  }

  static func == (lhs: Timetable, rhs: Timetable) -> Bool {
    return lhs.id == rhs.id && lhs.semester == rhs.semester
  }
}

extension Timetable {
  // Return the minimum start minutes.
  var minMinutes: Int {
    lectures
      .flatMap { $0.classTimes }
      .map { $0.begin }
      .min()
      .map { ($0 / 60) * 60 } ?? defaultMinMinutes
  }

  // Return the maximum end minutes.
  var maxMinutes: Int {
    lectures
      .flatMap { $0.classTimes }
      .map { $0.end }
      .max()
      .map { (($0 / 60) + 1) * 60 } ?? defaultMaxMinutes
  }

  // Return the maximum duration of the total timetable.
  var duration: Int { maxMinutes - minMinutes }

  // Return visible days. Return all weekdays by default, and check for the need of weekends inclusion.
  var visibleDays: [DayType] {
    let classDays = lectures.flatMap { $0.classTimes.map { $0.day } }
    let examDays = lectures.flatMap { $0.examTimes.map { $0.day } }

    let allDays = Array(Set(classDays + examDays + [.mon, .tue, .wed, .thu, .fri]))

    return allDays.sorted()
  }


  // Get all lectures for day. Return LectureItem that includes index of ClassTime of the Lecture.
  func getLectures(day: DayType) -> [LectureItem] {
    lectures
      .flatMap { lecture in
        lecture.classTimes.enumerated()
          .filter { $0.element.day == day }
          .map { LectureItem(lecture: lecture, index: $0.offset) }
      }
  }

  /*
   * For Timetable Summary
   */

  // Get the sum of credits
  var credits: Int {
    lectures
      .map { $0.credit }
      .reduce(0, +)
  }

  // Get the sum of AUs
  var creditAUs: Int {
    lectures
      .map { $0.creditAu }
      .reduce(0, +)
  }

  /*
   * targetCredits: sum of credit and creditAu where reviewTotalWeight is larger than 0. It is use to calculate letter for grade, load, and speech.
   */
  var targetCredits: Int {
    lectures
      .filter { $0.reviewTotalWeight > 0 }
      .map { $0.credit + $0.creditAu }
      .reduce(0, +)
  }

  private func calculateWeightedAverage(for keyPath: KeyPath<Lecture, Double>, withCredits: Bool = true) -> Double {
    let numerator = lectures
      .filter { $0.reviewTotalWeight > 0 }
      .map { $0[keyPath: keyPath] * Double($0.credit + (withCredits ? $0.creditAu : 0)) }
      .reduce(0.0, +)

    let denominator = lectures
      .filter { $0.reviewTotalWeight > 0 }
      .map { $0.credit + (withCredits ? $0.creditAu : 0) }
      .reduce(0, +)

    return denominator > 0 ? numerator / Double(denominator) : 0.0
  }

  // safely get letter grade string
  private func letter(for value: Double) -> String {
    let index = Int(round(value))
    return index >= 0 && index < letters.count ? letters[index] : "?"
  }

  // Letter grade for the grade
  var gradeLetter: String {
    letter(for: calculateWeightedAverage(for: \.grade))
  }

  // Letter grade for the load
  var loadLetter: String {
    letter(for: calculateWeightedAverage(for: \.load))
  }

  // Letter grade for the speech
  var speechLetter: String {
    letter(for: calculateWeightedAverage(for: \.speech))
  }

  // Get credits(credits, AUs) for the LectureType
  func getCreditsFor(_ type: LectureType) -> Int {
    lectures
      .filter { $0.type == type }
      .map { $0.credit + $0.creditAu }
      .reduce(0, +)
  }
}

struct LectureItem: Identifiable {
  let id = UUID()
  let lecture: Lecture
  let index: Int
}

struct Lecture: Identifiable {
  let id: Int
  let course: Int
  let code: String
  let section: String?
  let title: LocalizedString
  let department: LocalizedString
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

  var letters: [String] = [
    "?",
    "F",
    "F",
    "F",
    "D-",
    "D",
    "D+",
    "C-",
    "C",
    "C+",
    "B-",
    "B",
    "B+",
    "A-",
    "A",
    "A+"
  ]
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
    return index >= 0 && index < letters.count ? letters[index] : "?"
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

struct Professor: Identifiable {
  let id: Int
  let name: LocalizedString
  let reviewTotalWeight: Double
}

struct ClassTime {
  let classroomName: LocalizedString
  let classroomNameShort: LocalizedString
  let roomName: String
  let day: DayType
  let begin: Int
  let end: Int

  var duration: Int {
    end - begin
  }
}

struct ExamTime {
  let str: LocalizedString
  let day: DayType
  let begin: Int
  let end: Int

  var duration: Int {
    end - begin
  }
}

