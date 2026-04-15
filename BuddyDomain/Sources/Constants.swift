//
//  Constants.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

public enum Constants {
  // MARK: Infinite Scroll Constants
  public static let loadMoreThreshold = 0.6

  // MARK: App Store URL
  public static let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id6749929416")!

  // MARK: Terms
  public static let privacyPolicyURL = URL(string: "https://github.com/sparcs-kaist/privacy/blob/main/Privacy.md")!
  public static let termsOfUseURL = URL(string: "https://github.com/sparcs-kaist/privacy/blob/main/TermsOfUse.md")!

  // MARK: Taxi
  @MainActor public static let taxiRoomNameRegex = try? Regex(#"^[A-Za-z0-9가-힣ㄱ-ㅎㅏ-ㅣ,.?! _~/#'@="^()+*<>{}\\\[\]\-]{1,50}$"#)
  @MainActor public static let taxiNicknameRegex = try? Regex(#"^[A-Za-z가-힣ㄱ-ㅎㅏ-ㅣ0-9-_ ]{3,25}$"#)

  public static let taxiBankNameList = Array(taxiBankCodeMap.keys)

  public static let taxiInviteURL = {
    if Status.isProduction {
      return URL(string: "https://taxi.sparcs.org/invite/")!
    } else {
      return URL(string: "https://taxi.dev.sparcs.org/invite/")!
    }
  }()

  public static let taxiChatImageURL = {
    if Status.isProduction {
      return URL(string: "https://sparcs-taxi-prod.s3.ap-northeast-2.amazonaws.com/chat-img")!
    } else {
      return URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/chat-img")!
    }
  }()
  
  public static let taxiBankCodeMap: [String: String] = [
    "NH농협": "011",
    "KB국민": "004",
    "카카오뱅크": "090",
    "신한": "088",
    "우리": "020",
    "IBK기업": "003",
    "하나": "081",
    "토스뱅크": "092",
    "새마을": "045",
    "부산": "032",
    "대구": "031",
    "케이뱅크": "089",
    "신협": "048",
    "우체국": "071",
    "SC제일": "023",
    "경남": "039",
    "수협": "007",
    "광주": "034",
    "전북": "037",
    "저축은행": "050",
    "씨티": "027",
    "제주": "035",
    "KDB산업": "002",
    "산림": "064"
  ]
  
  public static let taxiDefaultRoomNames = [
    "택시 타고 가자",
    "택시 타고 가요",
    "모두 택시 타러 가요",
    "택시 타러 가요",
    "누가 걸어가요?",
    "편하게 택시 타요~",
    "운동은 나중에",
    "인생은 택시",
    "카이생의 택시",
    "택시로 떠나요",
    "택시의 세계로",
    "택시와 함께",
    "택시는 나의 행복",
    "매일매일 택시",
    "택시 없인 못살아",
    "택시, 나의 사랑",
    "택시로만 갈래요",
    "택시 아니면 안 갈래",
    "택시로 즐겁게",
    "택시, 내 인생의 선택",
    "택시의 시대",
    "택시로 날아봐요",
    "택시 타고 세상 구경",
    "오늘도 택시를 찾아",
    "택시로 나의 여행",
    "택시만이 내 길",
    "택시의 신세계",
    "택시로 멀리 가자",
    "택시의 꿈",
    "택시로 여행을 떠나요",
    "택시와 당신의 이야기",
    "택시로 새로운 세상",
    "택시와 소통하다",
    "택시의 숨결",
    "택시와 함께하는 날",
    "택시, 나의 운명",
    "택시로 떠나는 여행",
    "택시와 함께라면",
    "택시의 아름다운 순간",
    "택시의 소중한 인연",
    "택시로 새로운 만남",
    "택시, 나의 힐링",
    "택시의 행복한 미래",
    "택시와 나의 인생",
    "택시로 편안한 하루",
    "동승 친구들의 모임",
    "택시 공유의 순간",
    "동승, 기분 좋은 인연",
    "함께 가는 택시 여행",
    "택시 속의 만남",
    "동승 행복 나누기",
    "우리만의 택시 이야기",
    "택시 친구 찾기",
    "택시 동승 클럽",
    "택시 공유 친구들",
    "동승하며 대화 나누기",
    "친절한 동승",
    "택시와 함께하는 우정",
    "택시 동승 대화방",
    "동승 즐거운 만남",
    "택시 동승의 기쁨",
    "택시로 함께하는 길",
    "동승의 즐거움 나누기",
    "서로를 알아가는 택시",
    "택시 동행의 기쁨",
    "택시 동승 원더랜드",
    "지친 하루, 동승과 함께",
    "택시 동승 속 숨은 보물",
    "동승 힐링 여행",
    "택시 동승의 소중한 시간",
    "함께하는 택시 이야기",
    "택시 동승, 즐거운 시간",
    "택시 동승 미션",
    "택시 타고 함께 떠나요",
    "스마트한 동승 선택",
    "동승으로 더 나은 세상",
    "택시 동승, 새로운 만남",
    "환경을 생각하는 동승",
    "서로의 시간을 공유하다",
    "우리의 택시 동승 모험",
    "택시 동승, 신나는 여정",
    "택시 동승으로 인연 찾기",
    "택시 동승의 여유로운 시간",
    "좋은 인연, 택시 동승",
    "택시 동승, 행복한 선택",
    "동승 친구와의 대화",
    "택시 동승, 경제적인 선택",
    "무작정 택시 동승",
    "함께하는 택시 동승 경험",
    "택시 동승, 길 위의 친구",
    "택시 동승의 특별한 순간",
    "지금 바로 동승하기",
    "신나는 택시 동승 시간",
    "동승으로 시작하는 인연",
    "택시 동승의 소소한 이야기",
    "택시 동승의 아름다운 만남",
    "함께 타는 택시의 여유",
    "택시 동승, 새로운 경험",
    "함께하는 도심 속 여정",
    "집으로 가는 작은 여행",
    "가벼운 발걸음으로",
    "길 위의 소소한 대화",
    "함께하는 모험",
    "일상의 작은 탈출",
    "일상을 벗어나는 길",
    "함께 걷는 길",
    "동행이 있는 풍경",
    "함께하는 길목",
    "소소한 동행",
    "동승의 즐거움",
    "우리의 작은 여정",
    "함께 가는 순간",
    "길 위의 작은 이야기",
    "같이 가는 이 길",
    "택시 동승, 나의 여행",
    "함께 걷는 이야기",
    "함께하는 가벼운 발걸음",
    "동승으로 행복을 나누며",
    "소중한 동행 찾기",
    "함께하는 길, 더 가볍게",
    "동승과 함께하는 시간",
    "함께 타는 그 길",
    "동승의 소중한 순간들",
    "길동무를 찾아서",
    "함께라서 좋은 길",
    "동승, 그 작은 행복",
    "함께하는 드라이브",
    "동승, 우리의 이야기",
    "택시가 좋아요",
    "길 위의 소중한 동료",
    "여정 속의 동반자",
    "분주한 일상의 동행",
    "동승, 간직할 순간",
    "함께하는 순간의 가치",
    "동승으로 꾸는 꿈",
    "길 위의 작은 동행",
    "이야기가 있는 여정",
    "함께 만드는 길",
    "동행의 즐거운 발자국",
    "길 위의 벗과 함께",
    "우연히 만난 길동무",
    "동승의 미소를 나누며",
    "함께 타는 여정의 시작",
    "동승으로 풀어가는 이야기"
  ]

  public static let phoneNumberLength = 11
  
  // MARK: Ara
  public static let araPostURL = {
    if Status.isProduction {
      return URL(string: "https://newara.sparcs.org/post/")!
    } else {
      return URL(string: "https://newara.dev.sparcs.org/post/")!
    }
  }()
}
