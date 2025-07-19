//  Semester+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

#if DEBUG
import Foundation

extension Semester: Mockable {
    static var mock: Semester {
        Semester(
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
    }

    static var mockList: [Semester] {
        [
            Semester(
                year: 2022,
                semesterType: .autumn,
                beginDate: "2022-08-28T15:00:00.000Z".toDate()!,
                endDate: "2022-12-16T14:59:00.000Z".toDate()!,
                eventDate: SemesterEventDate(
                    registerationPeriodStartDate: "2022-08-08T03:30:00.000Z".toDate(),
                    registerationPeriodEndDate: "2022-08-12T14:59:00.000Z".toDate(),
                    addDropPeriodEndDate: "2022-09-05T14:59:00.000Z".toDate(),
                    dropDeadlineDate: "2022-10-14T14:59:00.000Z".toDate(),
                    evaluationDeadlineDate: "2022-12-09T14:59:00.000Z".toDate(),
                    gradePostingDate: "2022-12-23T01:00:00.000Z".toDate()
                )
            ),
            Semester(
                year: 2023,
                semesterType: .spring,
                beginDate: "2023-02-26T15:00:00.000Z".toDate()!,
                endDate: "2023-06-16T14:59:00.000Z".toDate()!,
                eventDate: SemesterEventDate(
                    registerationPeriodStartDate: "2023-01-02T03:30:00.000Z".toDate(),
                    registerationPeriodEndDate: "2023-01-06T14:59:00.000Z".toDate(),
                    addDropPeriodEndDate: "2023-03-06T14:59:00.000Z".toDate(),
                    dropDeadlineDate: "2023-04-14T14:59:00.000Z".toDate(),
                    evaluationDeadlineDate: "2023-06-09T14:59:00.000Z".toDate(),
                    gradePostingDate: "2023-06-23T01:00:00.000Z".toDate()
                )
            ),
            Semester(
                year: 2023,
                semesterType: .autumn,
                beginDate: "2023-08-28T15:00:00.000Z".toDate()!,
                endDate: "2023-12-15T14:59:00.000Z".toDate()!,
                eventDate: SemesterEventDate(
                    registerationPeriodStartDate: "2023-08-07T03:30:00.000Z".toDate(),
                    registerationPeriodEndDate: "2023-08-11T14:59:00.000Z".toDate(),
                    addDropPeriodEndDate: "2023-09-04T14:59:00.000Z".toDate(),
                    dropDeadlineDate: "2023-10-13T14:59:00.000Z".toDate(),
                    evaluationDeadlineDate: "2023-12-08T14:59:00.000Z".toDate(),
                    gradePostingDate: "2023-12-21T01:00:00.000Z".toDate()
                )
            ),
            Semester(
                year: 2024,
                semesterType: .spring,
                beginDate: "2024-02-25T15:00:00.000Z".toDate()!,
                endDate: "2024-06-14T14:59:00.000Z".toDate()!,
                eventDate: SemesterEventDate(
                    registerationPeriodStartDate: "2024-01-08T03:30:00.000Z".toDate(),
                    registerationPeriodEndDate: "2024-01-12T14:59:00.000Z".toDate(),
                    addDropPeriodEndDate: "2024-03-04T14:59:00.000Z".toDate(),
                    dropDeadlineDate: "2024-04-12T14:59:00.000Z".toDate(),
                    evaluationDeadlineDate: "2024-06-07T14:59:00.000Z".toDate(),
                    gradePostingDate: "2024-06-20T01:00:00.000Z".toDate()
                )
            ),
            Semester(
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
            ),
            Semester(
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
        ]
    }
}
#endif
