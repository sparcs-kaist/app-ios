//
//  Timetable+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation

extension Timetable: Mockable { }

public extension Timetable {
    static var mock: Timetable {
        Timetable(
            id: "0",
            lectures: Lecture.mockList
        )
    }

    static var mockList: [Timetable] {
        [
            Timetable(
                id: "0",
                lectures: realLectures
            ),
            Timetable(
                id: "1",
                lectures: Array(Lecture.mockList.prefix(1))
            ),
            Timetable(
                id: "2",
                lectures: []
            )
        ]
    }
}

private extension Timetable {
    // Real 2025 Fall lectures captured from the OTL API, mapped through LectureDTO.toModel().
    static var realLectures: [Lecture] {
        [
            Lecture(
                id: 1926802,
                courseID: 749,
                section: "",
                name: "프로그래밍언어",
                subtitle: "",
                code: "CS.30200",
                department: Department(id: 9945, name: "전산학부"),
                type: .mr,
                capacity: 270,
                enrolledCount: 133,
                credit: 3,
                creditAU: 0,
                grade: 12.44864094393468,
                load: 11.33585027958415,
                speech: 13.25336827109599,
                isEnglish: true,
                professors: [
                    Professor(id: 533, name: "류석영")
                ],
                classes: [
                    LectureClass(
                        day: .mon,
                        begin: 870,
                        end: 960,
                        buildingCode: "E11",
                        buildingName: "(E11)창의학습관",
                        roomName: "(104호)강의실-터만홀"
                    ),
                    LectureClass(
                        day: .wed,
                        begin: 870,
                        end: 960,
                        buildingCode: "E11",
                        buildingName: "(E11)창의학습관",
                        roomName: "(104호)강의실-터만홀"
                    )
                ],
                exams: [],
                classDuration: 3,
                expDuration: 0
            ),
            Lecture(
                id: 1927923,
                courseID: 89,
                section: "I",
                name: "일반화학실험 I",
                subtitle: "",
                code: "CH.10002",
                department: Department(id: 620, name: "화학과"),
                type: .br,
                capacity: 26,
                enrolledCount: 35,
                credit: 1,
                creditAU: 0,
                grade: 0,
                load: 0,
                speech: 0,
                isEnglish: false,
                professors: [
                    Professor(id: 5126, name: "박선아")
                ],
                classes: [
                    LectureClass(
                        day: .fri,
                        begin: 780,
                        end: 870,
                        buildingCode: "E6-5",
                        buildingName: "(E6-5)궁리실험관",
                        roomName: "(402호)강의실-학부 실험실"
                    ),
                    LectureClass(
                        day: .fri,
                        begin: 870,
                        end: 960,
                        buildingCode: "E6-5",
                        buildingName: "(E6-5)궁리실험관",
                        roomName: "(402호)강의실-학부 실험실"
                    )
                ],
                exams: [],
                classDuration: 0,
                expDuration: 3
            ),
            Lecture(
                id: 1928146,
                courseID: 2036,
                section: "A",
                name: "새내기 세미나 2",
                subtitle: "<건설및환경공학과>",
                code: "HSS.10090",
                department: Department(id: 20686, name: "디지털인문사회과학부"),
                type: .etc,
                capacity: 20,
                enrolledCount: 23,
                credit: 1,
                creditAU: 0,
                grade: 0,
                load: 0,
                speech: 0,
                isEnglish: false,
                professors: [
                    Professor(id: 4964, name: "고길완")
                ],
                classes: [
                    LectureClass(
                        day: .tue,
                        begin: 960,
                        end: 1020,
                        buildingCode: "W15",
                        buildingName: "(W15)스마트도시센터",
                        roomName: "(313호)강의실-강의실"
                    )
                ],
                exams: [],
                classDuration: 1,
                expDuration: 0
            ),
            Lecture(
                id: 1928379,
                courseID: 32,
                section: "A",
                name: "일반물리학 II",
                subtitle: "",
                code: "PH.10042",
                department: Department(id: 623, name: "물리학과"),
                type: .br,
                capacity: 115,
                enrolledCount: 114,
                credit: 3,
                creditAU: 0,
                grade: 14,
                load: 14,
                speech: 15,
                isEnglish: true,
                professors: [
                    Professor(id: 659, name: "민범기")
                ],
                classes: [
                    LectureClass(
                        day: .tue,
                        begin: 630,
                        end: 720,
                        buildingCode: "E11",
                        buildingName: "(E11)창의학습관",
                        roomName: "(311호)강의실"
                    ),
                    LectureClass(
                        day: .thu,
                        begin: 630,
                        end: 720,
                        buildingCode: "E11",
                        buildingName: "(E11)창의학습관",
                        roomName: "(311호)강의실"
                    )
                ],
                exams: [],
                classDuration: 3,
                expDuration: 1
            ),
            Lecture(
                id: 1928998,
                courseID: 132,
                section: "G",
                name: "미적분학Ⅱ",
                subtitle: "",
                code: "MAS.10002",
                department: Department(id: 833, name: "수리과학과"),
                type: .br,
                capacity: 60,
                enrolledCount: 89,
                credit: 3,
                creditAU: 0,
                grade: 12.07135784126389,
                load: 12.86136534080474,
                speech: 14.31090772735621,
                isEnglish: true,
                professors: [
                    Professor(id: 4033, name: "박지원")
                ],
                classes: [
                    LectureClass(
                        day: .tue,
                        begin: 780,
                        end: 870,
                        buildingCode: "E11",
                        buildingName: "(E11)창의학습관",
                        roomName: "(412호)강의실"
                    ),
                    LectureClass(
                        day: .thu,
                        begin: 780,
                        end: 870,
                        buildingCode: "E11",
                        buildingName: "(E11)창의학습관",
                        roomName: "(412호)강의실"
                    ),
                    LectureClass(
                        day: .fri,
                        begin: 600,
                        end: 660,
                        buildingCode: "",
                        buildingName: "()",
                        roomName: ""
                    )
                ],
                exams: [],
                classDuration: 3,
                expDuration: 1
            ),
            Lecture(
                id: 1929732,
                courseID: 24691,
                section: "",
                name: "시스템프로그래밍",
                subtitle: "",
                code: "AIC.20600",
                department: Department(id: 24354, name: "AI컴퓨팅학과"),
                type: .me,
                capacity: 10,
                enrolledCount: 9,
                credit: 3,
                creditAU: 0,
                grade: 0,
                load: 0,
                speech: 0,
                isEnglish: true,
                professors: [
                    Professor(id: 334, name: "허재혁")
                ],
                classes: [
                    LectureClass(
                        day: .tue,
                        begin: 870,
                        end: 960,
                        buildingCode: "N1",
                        buildingName: "(N1)김병호김삼열IT융합빌딩",
                        roomName: "(117호) 다목적홀"
                    ),
                    LectureClass(
                        day: .thu,
                        begin: 870,
                        end: 960,
                        buildingCode: "N1",
                        buildingName: "(N1)김병호김삼열IT융합빌딩",
                        roomName: "(117호) 다목적홀"
                    )
                ],
                exams: [],
                classDuration: 3,
                expDuration: 0
            ),
            Lecture(
                id: 1932260,
                courseID: 958,
                section: "O",
                name: "인성/리더십 III",
                subtitle: "<디자인 과제로부터 살아남기>",
                code: "HSS.10074",
                department: Department(id: 20686, name: "디지털인문사회과학부"),
                type: .etc,
                capacity: 20,
                enrolledCount: 5,
                credit: 0,
                creditAU: 1,
                grade: 14.74079314602902,
                load: 14.19168344058063,
                speech: 14.34696786168652,
                isEnglish: false,
                professors: [
                    Professor(id: 1, name: "Staff")
                ],
                classes: [
                    LectureClass(
                        day: .wed,
                        begin: 1200,
                        end: 1320,
                        buildingCode: "E11",
                        buildingName: "(E11)창의학습관",
                        roomName: "(210호)강의실"
                    )
                ],
                exams: [],
                classDuration: 1,
                expDuration: 0
            )
        ]
    }
}
