//
//  Lecture+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

#if DEBUG
extension Lecture: Mockable {
    static var mock: Lecture {
        Lecture(
            id: 1884981,
            course: 3423,
            code: "CE.20091",
            section: nil,
            year: 2024,
            semester: .autumn,
            title: LocalizedString(["ko": "지리공간 분석 개론", "en": "Introduction to Geospatial Analysis"]),
            department: LocalizedString(["ko": "건설및환경공학과", "en": "Civil and Environmental Engineering"]),
            isEnglish: true,
            credit: 3,
            creditAu: 0,
            capacity: 25,
            numberOfPeople: 35,
            grade: 14.63246654364472,
            load: 14.73445735528331,
            speech: 14.054518611026038,
            reviewTotalWeight: 16.325001,
            type: .me,
            typeDetail: LocalizedString(["ko": "전공선택", "en": "Major Elective"]),
            professors: [
                Professor(
                    id: 2368,
                    name: LocalizedString(["ko": "한동훈", "en": "Albert Tonghoon Han"]),
                    reviewTotalWeight: 59.009410940575314
                )
            ],
            classTimes: [
                ClassTime(
                    classroomName: LocalizedString(["ko": "(W1-2) 건설및환경공학과 1211", "en": "(W1-2) Dept. of Civil & Environmental Engineering 1211"]),
                    classroomNameShort: LocalizedString(["ko": "(W1-2) 1211", "en": "(W1-2) 1211"]),
                    roomName: "1211",
                    day: .mon,
                    begin: 780,
                    end: 870
                ),
                ClassTime(
                    classroomName: LocalizedString(["ko": "(W1-2) 건설및환경공학과 1211", "en": "(W1-2) Dept. of Civil & Environmental Engineering 1211"]),
                    classroomNameShort: LocalizedString(["ko": "(W1-2) 1211", "en": "(W1-2) 1211"]),
                    roomName: "1211",
                    day: .wed,
                    begin: 780,
                    end: 870
                )
            ],
            examTimes: [
                ExamTime(
                    str: LocalizedString(["ko": "월요일 13:00 ~ 15:45", "en": "Monday 13:00 ~ 15:45"]),
                    day: .mon,
                    begin: 780,
                    end: 945
                )
            ]
        )
    }
    
    static var mockList: [Lecture] {
        [
            Lecture(
                id: 1882911,
                course: 774,
                code: "CS.20002",
                section: nil,
                year: 2024,
                semester: .autumn,
                title: LocalizedString(["ko": "문제해결기법", "en": "Problem Solving"]),
                department: LocalizedString(["ko": "전산학부", "en": "School of Computing"]),
                isEnglish: false,
                credit: 3,
                creditAu: 0,
                capacity: 0,
                numberOfPeople: 225,
                grade: 15.000001,
                load: 13.176537392839839,
                speech: 14.54781488787623,
                reviewTotalWeight: 26.5377465836487,
                type: .me,
                typeDetail: LocalizedString(["ko": "전공선택", "en": "Major Elective"]),
                professors: [
                    Professor(
                        id: 1652,
                        name: LocalizedString(["ko": "류석영", "en": "Sukyoung Ryu"]),
                        reviewTotalWeight: 518.8789149987371
                    )
                ],
                classTimes: [
                    ClassTime(
                        classroomName: LocalizedString(["ko": "(E3) 정보전자공학동 1501", "en": "(E3) Information Science and Electronics Bldg. 1501"]),
                        classroomNameShort: LocalizedString(["ko": "(E3) 1501", "en": "(E3) 1501"]),
                        roomName: "1501",
                        day: .fri,
                        begin: 780,
                        end: 870
                    ),
                    ClassTime(
                        classroomName: LocalizedString(["ko": "(E3) 정보전자공학동 1501", "en": "(E3) Information Science and Electronics Bldg. 1501"]),
                        classroomNameShort: LocalizedString(["ko": "(E3) 1501", "en": "(E3) 1501"]),
                        roomName: "1501",
                        day: .fri,
                        begin: 870,
                        end: 960
                    )
                ],
                examTimes: []
            ),
            Lecture(
                id: 1882913,
                course: 745,
                code: "CS.20004",
                section: "A",
                year: 2024,
                semester: .autumn,
                title: LocalizedString(["ko": "이산구조", "en": "Discrete Mathematics"]),
                department: LocalizedString(["ko": "전산학부", "en": "School of Computing"]),
                isEnglish: true,
                credit: 3,
                creditAu: 0,
                capacity: 100,
                numberOfPeople: 158,
                grade: 14.12613402076768,
                load: 14.13128727171274,
                speech: 14.173633461345839,
                reviewTotalWeight: 113.9682314202921,
                type: .mr,
                typeDetail: LocalizedString(["ko": "전공필수", "en": "Major Required"]),
                professors: [
                    Professor(
                        id: 1534,
                        name: LocalizedString(["ko": "박진아", "en": "Park Jinah"]),
                        reviewTotalWeight: 123.2450553207218
                    )
                ],
                classTimes: [
                    ClassTime(
                        classroomName: LocalizedString(["ko": "(E11) 창의학습관 터만홀", "en": "(E11) Creative Learning Bldg. 터만홀"]),
                        classroomNameShort: LocalizedString(["ko": "(E11) 터만홀", "en": "(E11) 터만홀"]),
                        roomName: "터만홀",
                        day: .tue,
                        begin: 780,
                        end: 870
                    ),
                    ClassTime(
                        classroomName: LocalizedString(["ko": "(E11) 창의학습관 터만홀", "en": "(E11) Creative Learning Bldg. 터만홀"]),
                        classroomNameShort: LocalizedString(["ko": "(E11) 터만홀", "en": "(E11) 터만홀"]),
                        roomName: "터만홀",
                        day: .thu,
                        begin: 780,
                        end: 870
                    )
                ],
                examTimes: [
                    ExamTime(
                        str: LocalizedString(["ko": "화요일 13:00 ~ 15:45", "en": "Tuesday 13:00 ~ 15:45"]),
                        day: .tue,
                        begin: 780,
                        end: 945
                    )
                ]
            ),
            Lecture(
                id: 1882915,
                course: 746,
                code: "CS.20006",
                section: nil,
                year: 2024,
                semester: .autumn,
                title: LocalizedString(["ko": "데이타구조", "en": "Data Structure"]),
                department: LocalizedString(["ko": "전산학부", "en": "School of Computing"]),
                isEnglish: true,
                credit: 3,
                creditAu: 0,
                capacity: 0,
                numberOfPeople: 199,
                grade: 12.75854087583137,
                load: 14.35217200637648,
                speech: 13.98624399640883,
                reviewTotalWeight: 344.9845019592524,
                type: .mr,
                typeDetail: LocalizedString(["ko": "전공필수", "en": "Major Required"]),
                professors: [
                    Professor(
                        id: 39201,
                        name: LocalizedString(["ko": "문은영", "en": "Eun Young Moon"]),
                        reviewTotalWeight: 397.4670559664702
                    )
                ],
                classTimes: [
                    ClassTime(
                        classroomName: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        classroomNameShort: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        roomName: "",
                        day: .mon,
                        begin: 630,
                        end: 720
                    ),
                    ClassTime(
                        classroomName: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        classroomNameShort: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        roomName: "",
                        day: .wed,
                        begin: 630,
                        end: 720
                    )
                ],
                examTimes: [
                    ExamTime(
                        str: LocalizedString(["ko": "수요일 09:00 ~ 11:45", "en": "Wednesday 09:00 ~ 11:45"]),
                        day: .wed,
                        begin: 540,
                        end: 705
                    )
                ]
            ),
            Lecture(
                id: 1882917,
                course: 765,
                code: "CS.20300",
                section: nil,
                year: 2024,
                semester: .autumn,
                title: LocalizedString(["ko": "시스템프로그래밍", "en": "System Programming"]),
                department: LocalizedString(["ko": "전산학부", "en": "School of Computing"]),
                isEnglish: true,
                credit: 3,
                creditAu: 0,
                capacity: 0,
                numberOfPeople: 240,
                grade: 13.115049833673599,
                load: 8.975561454273896,
                speech: 13.81878472492449,
                reviewTotalWeight: 119.1822984880496,
                type: .me,
                typeDetail: LocalizedString(["ko": "전공선택", "en": "Major Elective"]),
                professors: [
                    Professor(
                        id: 2268,
                        name: LocalizedString(["ko": "박종세", "en": "Jongse Park"]),
                        reviewTotalWeight: 221.731841341158
                    )
                ],
                classTimes: [
                    ClassTime(
                        classroomName: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        classroomNameShort: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        roomName: "",
                        day: .tue,
                        begin: 870,
                        end: 960
                    ),
                    ClassTime(
                        classroomName: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        classroomNameShort: LocalizedString(["ko": "정보 없음", "en": "Unknown"]),
                        roomName: "",
                        day: .thu,
                        begin: 870,
                        end: 960
                    )
                ],
                examTimes: [
                    ExamTime(
                        str: LocalizedString(["ko": "목요일 13:00 ~ 15:45", "en": "Thursday 13:00 ~ 15:45"]),
                        day: .thu,
                        begin: 780,
                        end: 945
                    )
                ]
            ),
            Lecture(
                id: 1884981,
                course: 3423,
                code: "CE.20091",
                section: nil,
                year: 2024,
                semester: .autumn,
                title: LocalizedString(["ko": "지리공간 분석 개론", "en": "Introduction to Geospatial Analysis"]),
                department: LocalizedString(["ko": "건설및환경공학과", "en": "Civil and Environmental Engineering"]),
                isEnglish: true,
                credit: 3,
                creditAu: 0,
                capacity: 25,
                numberOfPeople: 35,
                grade: 14.63246654364472,
                load: 14.73445735528331,
                speech: 14.054518611026038,
                reviewTotalWeight: 16.325001,
                type: .me,
                typeDetail: LocalizedString(["ko": "전공선택", "en": "Major Elective"]),
                professors: [
                    Professor(
                        id: 2368,
                        name: LocalizedString(["ko": "한동훈", "en": "Albert Tonghoon Han"]),
                        reviewTotalWeight: 59.009410940575314
                    )
                ],
                classTimes: [
                    ClassTime(
                        classroomName: LocalizedString(["ko": "(W1-2) 건설및환경공학과 1211", "en": "(W1-2) Dept. of Civil & Environmental Engineering 1211"]),
                        classroomNameShort: LocalizedString(["ko": "(W1-2) 1211", "en": "(W1-2) 1211"]),
                        roomName: "1211",
                        day: .mon,
                        begin: 780,
                        end: 870
                    ),
                    ClassTime(
                        classroomName: LocalizedString(["ko": "(W1-2) 건설및환경공학과 1211", "en": "(W1-2) Dept. of Civil & Environmental Engineering 1211"]),
                        classroomNameShort: LocalizedString(["ko": "(W1-2) 1211", "en": "(W1-2) 1211"]),
                        roomName: "1211",
                        day: .wed,
                        begin: 780,
                        end: 870
                    )
                ],
                examTimes: [
                    ExamTime(
                        str: LocalizedString(["ko": "월요일 13:00 ~ 15:45", "en": "Monday 13:00 ~ 15:45"]),
                        day: .mon,
                        begin: 780,
                        end: 945
                    )
                ]
            )
        ]
    }
}

#endif
