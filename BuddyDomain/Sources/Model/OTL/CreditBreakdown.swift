//
//  CreditBreakdown.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import Foundation

/// Credits taken per requirement type, for graduation progress.
///
/// Counts follow `SemesterGradeSummary.earnedCredits`: every lecture counts except
/// F or NR ones (and U for AU), and ungraded lectures count as in progress.
public struct CreditBreakdown: Equatable, Sendable {
  /// Major Required / Elective credits taken in one department.
  public struct MajorGroup: Identifiable, Equatable, Sendable {
    public var id: Int { department.id }
    public var department: Department
    public var required: Int
    public var elective: Int
  }

  public private(set) var basicRequired = 0
  public private(set) var basicElective = 0
  /// The user's majors first (even with no credits yet), then other departments by name.
  public private(set) var majors: [MajorGroup] = []
  public private(set) var hseCore = 0
  public private(set) var hseGeneral = 0
  /// HSS electives without a core/general subcategory (older curricula).
  public private(set) var hse = 0
  public private(set) var au = 0
  public private(set) var etc = 0

  public init(lectures: [Lecture], grades: [Int: LectureGrade], majorDepartments: [Department]) {
    var ownMajors = majorDepartments.map {
      MajorGroup(department: $0, required: 0, elective: 0)
    }
    var otherMajors: [Int: MajorGroup] = [:]

    for lecture in lectures {
      let grade = grades[lecture.id]
      guard grade != .fail, grade != .nonRecord else { continue }
      if grade != .unsatisfied { au += lecture.creditAU }

      let credit = lecture.credit
      switch lecture.type {
      case .br: basicRequired += credit
      case .be: basicElective += credit
      case .hseCore: hseCore += credit
      case .hseGeneral: hseGeneral += credit
      case .hse: hse += credit
      case .etc: etc += credit
      case .mr, .me:
        let isRequired = lecture.type == .mr
        // OTL can list the same department under different IDs, so match the name too.
        if let index = ownMajors.firstIndex(where: {
          $0.department.id == lecture.department.id || $0.department.name == lecture.department.name
        }) {
          // Show the lecture's name: the profile's can be in another language than
          // the lecture data, which follows the app language like the other headers.
          ownMajors[index].department = lecture.department
          if isRequired { ownMajors[index].required += credit } else { ownMajors[index].elective += credit }
        } else {
          var group = otherMajors[lecture.department.id]
            ?? MajorGroup(department: lecture.department, required: 0, elective: 0)
          if isRequired { group.required += credit } else { group.elective += credit }
          otherMajors[lecture.department.id] = group
        }
      }
    }

    majors = ownMajors + otherMajors.values
      .filter { $0.required + $0.elective > 0 }
      .sorted { $0.department.name < $1.department.name }
  }
}
