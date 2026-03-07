//
//  V2CourseSummary+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

extension V2CourseSummary: Mockable { }

public extension V2CourseSummary {
  static var mock: V2CourseSummary {
    V2CourseSummary(
      id: 16614,
      code: "CS.20300",
      name: "System Programming",
      summary: "Learn system-level programming with a focus on OS concepts and low-level abstractions.",
      department: V2Department(id: 9945, name: "School of Computing"),
      professors: [
        V2Professor(id: 2269, name: "Jane Doe"),
        V2Professor(id: 2438, name: "John Smith")
      ],
      type: .me,
      completed: false,
      open: true
    )
  }

  static var mockList: [V2CourseSummary] {
    [
      V2CourseSummary(
        id: 16614,
        code: "CS.20300",
        name: "System Programming",
        summary: "Learn system-level programming with a focus on OS concepts and low-level abstractions.",
        department: V2Department(id: 9945, name: "School of Computing"),
        professors: [
          V2Professor(id: 2269, name: "Jane Doe"),
          V2Professor(id: 2438, name: "John Smith")
        ],
        type: .me,
        completed: false,
        open: true
      ),
      V2CourseSummary(
        id: 18725,
        code: "EE311",
        name: "Operating Systems for Electrical Engineering",
        summary: "",
        department: V2Department(id: 3845, name: "Department of Electrical Engineering"),
        professors: [
          V2Professor(id: 1951, name: "Chris Park")
        ],
        type: .me,
        completed: true,
        open: false
      ),
      V2CourseSummary(
        id: 17002,
        code: "CS.30300",
        name: "Operating Systems and Lab",
        summary: "Covers OS fundamentals with hands-on labs and systems design exercises.",
        department: V2Department(id: 9945, name: "School of Computing"),
        professors: [
          V2Professor(id: 2510, name: "Alex Kim")
        ],
        type: .mr,
        completed: false,
        open: true
      )
    ]
  }
}
