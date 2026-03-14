//
//  CourseSummary+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

extension CourseSummary: Mockable { }

public extension CourseSummary {
  static var mock: CourseSummary {
    CourseSummary(
      id: 16614,
      code: "CS.20300",
      name: "System Programming",
      summary: "Learn system-level programming with a focus on OS concepts and low-level abstractions.",
      department: Department(id: 9945, name: "School of Computing", code: nil),
      professors: [
        Professor(id: 2269, name: "Jane Doe"),
        Professor(id: 2438, name: "John Smith")
      ],
      type: .me,
      completed: false,
      open: true
    )
  }

  static var mockList: [CourseSummary] {
    [
      CourseSummary(
        id: 16614,
        code: "CS.20300",
        name: "System Programming",
        summary: "Learn system-level programming with a focus on OS concepts and low-level abstractions.",
        department: Department(id: 9945, name: "School of Computing", code: nil),
        professors: [
          Professor(id: 2269, name: "Jane Doe"),
          Professor(id: 2438, name: "John Smith")
        ],
        type: .me,
        completed: false,
        open: true
      ),
      CourseSummary(
        id: 18725,
        code: "EE311",
        name: "Operating Systems for Electrical Engineering",
        summary: "",
        department: Department(id: 3845, name: "Department of Electrical Engineering", code: nil),
        professors: [
          Professor(id: 1951, name: "Chris Park")
        ],
        type: .me,
        completed: true,
        open: false
      ),
      CourseSummary(
        id: 17002,
        code: "CS.30300",
        name: "Operating Systems and Lab",
        summary: "Covers OS fundamentals with hands-on labs and systems design exercises.",
        department: Department(id: 9945, name: "School of Computing", code: nil),
        professors: [
          Professor(id: 2510, name: "Alex Kim")
        ],
        type: .mr,
        completed: false,
        open: true
      )
    ]
  }
}
