//
//  LectureReview+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 02/10/2025.
//

import Foundation
import BuddyDomain

extension LectureReview: Mockable { }

public extension LectureReview {
  static var mock: LectureReview {
    LectureReview(
      id: 28073,
      lecture: Lecture(
        id: 1884766,
        course: 16614,
        code: "AE.30007",
        section: "A",
        year: 2024,
        semester: .autumn,
        title: LocalizedString([
          "ko": "항공우주공학 실험Ⅱ",
          "en": "Aerospace Engineering LaboratoryⅡ"
        ]),
        department: Department(
          id: 9944,
          name: LocalizedString([
            "ko": "항공우주공학과",
            "en": "Department of Aerospace Engineering"
          ]),
          code: "AE"
        ),
        isEnglish: true,
        credit: 3,
        creditAu: 0,
        capacity: 0,
        numberOfPeople: 30,
        grade: 0.0,
        load: 0.0,
        speech: 0.0,
        reviewTotalWeight: 8.41252029881456,
        type: .mr,
        typeDetail: LocalizedString([
          "ko": "전공필수",
          "en": "Major Required"
        ]),
        professors: [
          Professor(
            id: 2269,
            name: LocalizedString([
              "ko": "이상봉",
              "en": "Lee  Sang"
            ]),
            reviewTotalWeight: 16.26581440301713
          ),
          Professor(
            id: 2438,
            name: LocalizedString([
              "ko": "이전윤",
              "en": "Lee, Jeonyoon"
            ]),
            reviewTotalWeight: 36.97639056965616
          )
        ],
        classTimes: [],
        examTimes: []
      ),
      content: "실험 짧고, 성적도 후하고, 어느 정도 쓰기만 하면 좋습니다.\n\n공기역학은 압축성 공기역학 지식이 좀 많이 나와서 그걸 같이 듣거나 주변에 압공을 듣는 사람이 있다면 아주 좋습니다.\n\n공기역학 보고서는 성적이 안나와서 모르겠는데 그냥 무난히 쓰니까 A0 나옵니다. 잘 주는 것 같습니다.\n\n수업 시간에 시험이 없다보니 학생들이 잘 안들으나, 들으면 좋은 내용이 너무 많이 나와서 듣는 것을 추천드립니다.",
      like: 1,
      grade: 4,
      load: 4,
      speech: 5,
      isDeleted: false,
      isLiked: false
    )
  }
  
  static var mockList: [LectureReview] {
    [
      LectureReview(
        id: 28073,
        lecture: Lecture(
          id: 1884766,
          course: 16614,
          code: "AE.30007",
          section: "A",
          year: 2024,
          semester: .autumn,
          title: LocalizedString([
            "ko": "항공우주공학 실험Ⅱ",
            "en": "Aerospace Engineering LaboratoryⅡ"
          ]),
          department: Department(
            id: 9944,
            name: LocalizedString([
              "ko": "항공우주공학과",
              "en": "Department of Aerospace Engineering"
            ]),
            code: "AE"
          ),
          isEnglish: true,
          credit: 3,
          creditAu: 0,
          capacity: 0,
          numberOfPeople: 30,
          grade: 0.0,
          load: 0.0,
          speech: 0.0,
          reviewTotalWeight: 8.41252029881456,
          type: .mr,
          typeDetail: LocalizedString([
            "ko": "전공필수",
            "en": "Major Required"
          ]),
          professors: [
            Professor(
              id: 2269,
              name: LocalizedString([
                "ko": "이상봉",
                "en": "Lee  Sang"
              ]),
              reviewTotalWeight: 16.26581440301713
            ),
            Professor(
              id: 2438,
              name: LocalizedString([
                "ko": "이전윤",
                "en": "Lee, Jeonyoon"
              ]),
              reviewTotalWeight: 36.97639056965616
            )
          ],
          classTimes: [],
          examTimes: []
        ),
        content: "실험 짧고, 성적도 후하고, 어느 정도 쓰기만 하면 좋습니다.\n\n공기역학은 압축성 공기역학 지식이 좀 많이 나와서 그걸 같이 듣거나 주변에 압공을 듣는 사람이 있다면 아주 좋습니다.\n\n공기역학 보고서는 성적이 안나와서 모르겠는데 그냥 무난히 쓰니까 A0 나옵니다. 잘 주는 것 같습니다.\n\n수업 시간에 시험이 없다보니 학생들이 잘 안들으나, 들으면 좋은 내용이 너무 많이 나와서 듣는 것을 추천드립니다.",
        like: 1,
        grade: 4,
        load: 4,
        speech: 5,
        isDeleted: false,
        isLiked: false
      ),
      LectureReview(
        id: 24208,
        lecture: Lecture(
          id: 1872561,
          course: 16614,
          code: "AE.30007",
          section: "A",
          year: 2023,
          semester: .autumn,
          title: LocalizedString([
            "ko": "항공우주공학 실험Ⅱ",
            "en": "Aerospace Engineering LaboratoryⅡ"
          ]),
          department: Department(
            id: 9944,
            name: LocalizedString([
              "ko": "항공우주공학과",
              "en": "Department of Aerospace Engineering"
            ]),
            code: "AE"
          ),
          isEnglish: true,
          credit: 3,
          creditAu: 0,
          capacity: 80,
          numberOfPeople: 30,
          grade: 0.0,
          load: 0.0,
          speech: 0.0,
          reviewTotalWeight: 12.84513637068956,
          type: .mr,
          typeDetail: LocalizedString([
            "ko": "전공필수",
            "en": "Major Required"
          ]),
          professors: [
            Professor(
              id: 1951,
              name: LocalizedString([
                "ko": "박기수",
                "en": "Park, Gi Su"
              ]),
              reviewTotalWeight: 48.71305440040448
            ),
            Professor(
              id: 2438,
              name: LocalizedString([
                "ko": "이전윤",
                "en": "Lee, Jeonyoon"
              ]),
              reviewTotalWeight: 36.97639056965616
            )
          ],
          classTimes: [],
          examTimes: []
        ),
        content: "중간 이전에는 공기역학, 중간 이후에는 구조 관련 실험을 합니다. 공기 실험은 조교님들께서 세팅해 놓은 것에 간단한 조작만 하면 되고 구조 실험은 조교님들께서 다 해주십니다. 실험 자체는 매우 간단하고 빠르게 끝나지만 보고서 쓰는게 조금 빡셉니다. 특히, 공기 실험은 주어진 양식도 맞춰야해서 신경쓸게 많습니다. 점수 평균이 워낙 높아서(164.09/170) 조금만(2점 이상) 감점되어도 그레이드가 낮아지니 감점 안 당하게 꼼꼼히 쓰세요.",
        like: 2,
        grade: 4,
        load: 4,
        speech: 5,
        isDeleted: false,
        isLiked: false
      ),
      LectureReview(
        id: 24190,
        lecture: Lecture(
          id: 1872561,
          course: 16614,
          code: "AE.30007",
          section: "A",
          year: 2023,
          semester: .autumn,
          title: LocalizedString([
            "ko": "항공우주공학 실험Ⅱ",
            "en": "Aerospace Engineering LaboratoryⅡ"
          ]),
          department: Department(
            id: 9944,
            name: LocalizedString([
              "ko": "항공우주공학과",
              "en": "Department of Aerospace Engineering"
            ]),
            code: "AE"
          ),
          isEnglish: true,
          credit: 3,
          creditAu: 0,
          capacity: 80,
          numberOfPeople: 30,
          grade: 0.0,
          load: 0.0,
          speech: 0.0,
          reviewTotalWeight: 12.84513637068956,
          type: .mr,
          typeDetail: LocalizedString([
            "ko": "전공필수",
            "en": "Major Required"
          ]),
          professors: [
            Professor(
              id: 1951,
              name: LocalizedString([
                "ko": "박기수",
                "en": "Park, Gi Su"
              ]),
              reviewTotalWeight: 48.71305440040448
            ),
            Professor(
              id: 2438,
              name: LocalizedString([
                "ko": "이전윤",
                "en": "Lee, Jeonyoon"
              ]),
              reviewTotalWeight: 36.97639056965616
            )
          ],
          classTimes: [],
          examTimes: []
        ),
        content: "박기수 교수님, 이전윤 교수님께서 각각 8주씩 수업을 진행하시고 총 8개의 보고서를 작성합니다.\n\n성적\n166/170 A0\n총점에서 4점 깎여 A0 받았는데, 평균이 164/170으로 워낙 높아서 A+은 받지 못한 것으로 생각됩니다.\n\n로드\n하나의 실험이 끝나면 2주 후 까지 보고서를 작성하여 제출해야 하며, 주어진 양식에 맞게 제출해야 합니다. 제가 보고서를 적는데 오래 걸리는 편이라 하나의 보고서를 작성하는데 10시간 이상은 걸렸습니다.\n\n강의 및 실험\n1~8주 박기수 교수님\n풍동을 이용하여 공기역학과 관련된 실험을 진행하며 수업 때 출석 체크를 진행합니다. 실험 세팅은 조교님들께서 다 해주시고 풍동 시작 버튼이나 실린더 각도 조정 정도만 학생들이 직접합니다. 세 개의 보고서를 작성하며 보고서 1, 2의 경우 아음속 풍동에 관련된 내용을 적기 때문에 크게 어렵지 않습니다. 보고서 3의 경우 초음속에 대해 다루기 때문에 압축성 공기역학에 대한 내용이 사용되기는 하나 수업 시간에 잘 알려주시기 때문에 압축성 공기역학을 모르더라도 크게 어렵지는 않습니다.\n\n9~18주 이전윤 교수님\n재료와 관련된 실험을 진행하며 수업 때 출석을 체크하지 않습니다. 실험 세팅과 진행까지 조교님들께서 다 해주십니다. 5개의 보고서를 작성하며 풍동 실험 보고서 보다는 분량이 짧습니다. 복합재와 관련된 보고서 8을 제외하고는 재료역학에서 배운 내용을 바탕으로 모두 작성할 수 있습니다.\n\n",
        like: 1,
        grade: 4,
        load: 3,
        speech: 5,
        isDeleted: false,
        isLiked: false
      )
    ]
  }
}
