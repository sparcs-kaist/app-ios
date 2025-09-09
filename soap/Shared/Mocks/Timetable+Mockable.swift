//
//  Timetable+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import Foundation

extension Timetable: Mockable {
    static var mock: Timetable {
        Timetable(
            id: 0,
            lectures: Lecture.mockList,
            semester: Semester(
                year: 2024,
                semesterType: .autumn,
                beginDate: "2024-09-01T15:00:00.000Z".toDate()!,
                endDate: "2024-12-20T14:59:00.000Z".toDate()!,
                eventDate: SemesterEventDate(
                    registerationPeriodStartDate: "2024-08-12T03:30:00.000Z".toDate(),
                    registerationPeriodEndDate: "2024-08-16T14:59:00.000Z".toDate(),
                    addDropPeriodEndDate: "2024-09-09T14:59:00.000Z".toDate(),
                    dropDeadlineDate: "2024-10-18T14:59:00.000Z".toDate(),
                    evaluationDeadlineDate: "2024-12-13T14:59:00.000Z".toDate(),
                    gradePostingDate: "2024-12-26T01:00:00.000Z".toDate()
                )
            )
        )
    }
    
    static var mockList: [Timetable] {
        [
            Timetable(
                id: 0,
                lectures: Lecture.mockList,
                semester: Semester(
                    year: 2024,
                    semesterType: .autumn,
                    beginDate: "2024-09-01T15:00:00.000Z".toDate()!,
                    endDate: "2024-12-20T14:59:00.000Z".toDate()!,
                    eventDate: SemesterEventDate(
                        registerationPeriodStartDate: "2024-08-12T03:30:00.000Z".toDate(),
                        registerationPeriodEndDate: "2024-08-16T14:59:00.000Z".toDate(),
                        addDropPeriodEndDate: "2024-09-09T14:59:00.000Z".toDate(),
                        dropDeadlineDate: "2024-10-18T14:59:00.000Z".toDate(),
                        evaluationDeadlineDate: "2024-12-13T14:59:00.000Z".toDate(),
                        gradePostingDate: "2024-12-26T01:00:00.000Z".toDate()
                    )
                )
            ),
            Timetable(
                id: 1,
                lectures: Lecture.mockList,
                semester: Semester(
                    year: 2024,
                    semesterType: .autumn,
                    beginDate: "2024-09-01T15:00:00.000Z".toDate()!,
                    endDate: "2024-12-20T14:59:00.000Z".toDate()!,
                    eventDate: SemesterEventDate(
                        registerationPeriodStartDate: "2024-08-12T03:30:00.000Z".toDate(),
                        registerationPeriodEndDate: "2024-08-16T14:59:00.000Z".toDate(),
                        addDropPeriodEndDate: "2024-09-09T14:59:00.000Z".toDate(),
                        dropDeadlineDate: "2024-10-18T14:59:00.000Z".toDate(),
                        evaluationDeadlineDate: "2024-12-13T14:59:00.000Z".toDate(),
                        gradePostingDate: "2024-12-26T01:00:00.000Z".toDate()
                    )
                )
            ),
            Timetable(
                id: 2,
                lectures: Lecture.mockList,
                semester: Semester(
                    year: 2024,
                    semesterType: .autumn,
                    beginDate: "2024-09-01T15:00:00.000Z".toDate()!,
                    endDate: "2024-12-20T14:59:00.000Z".toDate()!,
                    eventDate: SemesterEventDate(
                        registerationPeriodStartDate: "2024-08-12T03:30:00.000Z".toDate(),
                        registerationPeriodEndDate: "2024-08-16T14:59:00.000Z".toDate(),
                        addDropPeriodEndDate: "2024-09-09T14:59:00.000Z".toDate(),
                        dropDeadlineDate: "2024-10-18T14:59:00.000Z".toDate(),
                        evaluationDeadlineDate: "2024-12-13T14:59:00.000Z".toDate(),
                        gradePostingDate: "2024-12-26T01:00:00.000Z".toDate()
                    )
                )
            ),
            Timetable(
                id: 0,
                lectures: Lecture.mockList,
                semester: Semester(
                    year: 2025,
                    semesterType: .spring,
                    beginDate: "2025-02-23T15:00:00.000Z".toDate()!,
                    endDate: "2025-06-13T14:59:00.000Z".toDate()!,
                    eventDate: SemesterEventDate(
                        registerationPeriodStartDate: "2025-01-06T03:30:00.000Z".toDate(),
                        registerationPeriodEndDate: "2025-01-10T14:59:00.000Z".toDate(),
                        addDropPeriodEndDate: "2025-03-04T14:59:00.000Z".toDate(),
                        dropDeadlineDate: "2025-04-11T14:59:00.000Z".toDate(),
                        evaluationDeadlineDate: "2025-06-06T14:59:00.000Z".toDate(),
                        gradePostingDate: "2025-06-19T01:00:00.000Z".toDate()
                    )
                )
            )
        ]
    }
}
