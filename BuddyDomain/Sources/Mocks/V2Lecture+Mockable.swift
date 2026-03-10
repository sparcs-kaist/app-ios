//
//  V2Lecture+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/03/2026.
//

import Foundation

extension V2Lecture: Mockable { }

public extension V2Lecture {
  static var mock: V2Lecture {
    V2Lecture(
      id: 10101,
      courseID: 20300,
      section: "A",
      name: "System Programming",
      subtitle: "Fall 2025",
      code: "CS.20300",
      department: V2Department(id: 9945, name: "School of Computing"),
      type: .me,
      capacity: 45,
      enrolledCount: 42,
      credit: 3,
      creditAU: 0,
      grade: 4.2,
      load: 3.8,
      speech: 4.0,
      isEnglish: true,
      professors: [
        V2Professor(id: 2269, name: "Jane Doe")
      ],
      classes: [
        V2LectureClass(
          day: .mon,
          begin: 540,
          end: 630,
          buildingCode: "E11",
          buildingName: "Creative Learning B/D",
          roomName: "304"
        ),
        V2LectureClass(
          day: .wed,
          begin: 540,
          end: 630,
          buildingCode: "E11",
          buildingName: "Creative Learning B/D",
          roomName: "304"
        )
      ],
      exams: [
        V2LectureExam(
          day: .thu,
          description: "Midterm",
          begin: 600,
          end: 720
        )
      ],
      classDuration: 90,
      expDuration: 120
    )
  }

  static var mockList: [V2Lecture] {
    [
      V2Lecture(
        id: 10101,
        courseID: 20300,
        section: "A",
        name: "System Programming",
        subtitle: "Fall 2025",
        code: "CS.20300",
        department: V2Department(id: 9945, name: "School of Computing"),
        type: .me,
        capacity: 45,
        enrolledCount: 42,
        credit: 3,
        creditAU: 0,
        grade: 4.2,
        load: 3.8,
        speech: 4.0,
        isEnglish: true,
        professors: [
          V2Professor(id: 2269, name: "Jane Doe")
        ],
        classes: [
          V2LectureClass(
            day: .mon,
            begin: 540,
            end: 630,
            buildingCode: "E11",
            buildingName: "Creative Learning B/D",
            roomName: "304"
          ),
          V2LectureClass(
            day: .wed,
            begin: 540,
            end: 630,
            buildingCode: "E11",
            buildingName: "Creative Learning B/D",
            roomName: "304"
          )
        ],
        exams: [
          V2LectureExam(
            day: .thu,
            description: "Midterm",
            begin: 600,
            end: 720
          )
        ],
        classDuration: 90,
        expDuration: 120
      ),
      V2Lecture(
        id: 10102,
        courseID: 31100,
        section: "B",
        name: "Operating Systems",
        subtitle: "Fall 2025",
        code: "CS.31100",
        department: V2Department(id: 9945, name: "School of Computing"),
        type: .mr,
        capacity: 60,
        enrolledCount: 58,
        credit: 3,
        creditAU: 0,
        grade: 4.0,
        load: 3.6,
        speech: 3.7,
        isEnglish: false,
        professors: [
          V2Professor(id: 2438, name: "John Smith")
        ],
        classes: [
          V2LectureClass(
            day: .tue,
            begin: 660,
            end: 750,
            buildingCode: "E3",
            buildingName: "Tech Building",
            roomName: "201"
          ),
          V2LectureClass(
            day: .thu,
            begin: 660,
            end: 750,
            buildingCode: "E3",
            buildingName: "Tech Building",
            roomName: "201"
          )
        ],
        exams: [
          V2LectureExam(
            day: .fri,
            description: "Final",
            begin: 540,
            end: 720
          )
        ],
        classDuration: 90,
        expDuration: 120
      )
    ]
  }
}
