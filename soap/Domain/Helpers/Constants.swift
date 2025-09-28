//
//  Constants.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

enum Constants {
  // MARK: Authorisation
  static let authorisationURL = URL(string: "https://taxi.dev.sparcs.org/api/auth/sparcsapp/login")

  // MARK: Taxi
  static let taxiBackendURL = URL(string: "https://taxi.dev.sparcs.org/api")!
  static let taxiSocketURL = URL(string: "https://taxi.dev.sparcs.org/")!
  static let taxiChatImageURL = URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/chat-img")!

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
  static let taxiBankNameList = Array(taxiBankCodeMap.keys)
  
  static let taxiInviteURL = URL(string: "https://taxi.dev.sparcs.org/invite/")!

  // MARK: Ara
  static let araBackendURL = URL(string: "https://newara.dev.sparcs.org/api")!

  // MARK: Feed
  static let feedBackendURL = URL(string: "https://app.dev.sparcs.org/v1")!
}
