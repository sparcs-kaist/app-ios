//
//  V2Timetable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import SwiftUI

public struct V2Timetable: Hashable, Codable, Sendable {
  public var lectures: [V2Lecture]

  private var defaultMinMinutes = 540 // 9:00 AM
  private var defaultMaxMinutes = 1080 // 6:00 PM

  public static let letters: [String] = [
    "?", "F", "F", "F", "D-", "D", "D+", "C-", "C", "C+",
    "B-", "B", "B+", "A-", "A", "A+"
  ]

  public init(lectures: [V2Lecture]) {
    self.lectures = lectures
  }
}

public extension V2Timetable {
  // Return the minimum start minutes.
  var minMinutes: Int {
    lectures
      .flatMap { $0.classes }
      .map { $0.begin }
      .min()
      .map { ($0 / 60) * 60 } ?? defaultMinMinutes
  }

  // Return the maximum end minutes.
  var gappedMaxMinutes: Int {
    lectures
      .flatMap { $0.classes }
      .map { $0.end }
      .max()
      .map { (($0 / 60) + 1) * 60 } ?? defaultMaxMinutes
  }

  var maxMinutes: Int {
    lectures
      .flatMap { $0.classes }
      .map { $0.end }
      .max() ?? defaultMaxMinutes
  }

  // Return the maximum duration of the total timetable.
  var gappedDuration: Int { gappedMaxMinutes - minMinutes }
  var duration: Int { maxMinutes - minMinutes }

  // Return visible days. Return all weekdays by default, and check for the need of weekends inclusion.
  var visibleDays: [DayType] {
    let classDays = lectures.flatMap { $0.classes.map { $0.day } }

    let combinedDays = Array(Set(classDays + DayType.weekdays))

    return combinedDays.sorted()
  }


  // Get all lectures for day. Return LectureItem that includes index of ClassTime of the Lecture.
  func getLectures(day: DayType) -> [V2LectureItem] {
    lectures
      .flatMap { lecture in
        lecture.classes.enumerated()
          .filter { $0.element.day == day }
          .map {
            V2LectureItem(lecture: lecture, lectureClass: lecture.classes[$0.offset])
          }
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
      .map { $0.creditAU }
      .reduce(0, +)
  }

  /*
   * targetCredits: sum of credit and creditAu where reviewTotalWeight is larger than 0. It is use to calculate letter for grade, load, and speech.
   */
  var targetCredits: Int {
    lectures
      .map { $0.credit + $0.creditAU }
      .reduce(0, +)
  }

  private func calculateWeightedAverage(for keyPath: KeyPath<V2Lecture, Double>, withCredits: Bool = true) -> Double {

    let numerator = lectures
      .map { $0[keyPath: keyPath] * Double($0.credit + (withCredits ? $0.creditAU : 0)) }
      .reduce(0.0, +)

    let denominator = lectures
      .map { $0.credit + (withCredits ? $0.creditAU : 0) }
      .reduce(0, +)

    return denominator > 0 ? numerator / Double(denominator) : 0.0
  }

  // safely get letter grade string
  private func letter(for value: Double) -> String {
    let index = Int(round(value))
    return Timetable.letters[safe: index] ?? "?"
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
      .map { $0.credit + $0.creditAU }
      .reduce(0, +)
  }

  func hasCollision(with newLecture: Lecture) -> Bool {
    for existingLecture in lectures {
      for existingTime in existingLecture.classes {
        for newTime in newLecture.classTimes {
          if existingTime.day == newTime.day {
            // Overlap occurs if start < other.end && end > other.start
            if newTime.begin < existingTime.end && newTime.end > existingTime.begin {
              return true
            }
          }
        }
      }
    }
    return false
  }

  func lectureItems(for date: Date = Date()) -> [V2LectureItem] {
    let today = DayType.from(date: date, calendar: .current)

    var next: [V2LectureItem] = []
    for lecture in self.lectures {
      for (i, ct) in lecture.classes.enumerated() where ct.day == today {
        next.append(V2LectureItem(lecture: lecture, lectureClass: lecture.classes[i]))
      }
    }

    return next.sorted {
      let a = $0.lectureClass.begin
      let b = $1.lectureClass.begin
      return a < b
    }
  }
}
