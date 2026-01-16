//
//  Constants.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import BuddyDataCore

enum Constants {
  // MARK: Infinite Scroll Constants
  static let loadMoreThreshold = 0.6
  
  // MARK: App Store URL
  // TODO: Fill with real app ID
  static let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app")!
  
  // MARK: Terms
  static let privacyPolicyURL = URL(string: "https://github.com/sparcs-kaist/privacy/blob/main/Privacy.md")!
  static let termsOfUseURL = URL(string: "https://github.com/sparcs-kaist/privacy/blob/main/TermsOfUse.md")!

  static let taxiBankCodeMap: [String: String] = [
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
  
  // MARK: Taxi
  @MainActor static let taxiRoomNameRegex = try? Regex(#"^[A-Za-z0-9가-힣ㄱ-ㅎㅏ-ㅣ,.?! _~/#'@="^()+*<>{}\\\[\]\-]{1,50}$"#)
  
  static let taxiBankNameList = Array(taxiBankCodeMap.keys)

  static let taxiInviteURL = {
    if Status.isProduction {
      return URL(string: "https://taxi.sparcs.org/invite/")!
    } else {
      return URL(string: "https://taxi.dev.sparcs.org/invite/")!
    }
  }()
  
  static let taxiChatImageURL = {
    if Status.isProduction {
      return URL(string: "https://sparcs-taxi-prod.s3.ap-northeast-2.amazonaws.com/chat-img")!
    } else {
      return URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/chat-img")!
    }
  }()

  static let araPostURL = {
    if Status.isProduction {
      return URL(string: "https://newara.sparcs.org/post/")!
    } else {
      return URL(string: "https://newara.dev.sparcs.org/post/")!
    }
  }()

  static let phoneNumberLength = 11
}
