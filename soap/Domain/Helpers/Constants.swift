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
  static let taxiSocketURL = URL(string: "https://taxi.dev.sparcs.org")!
  static let taxiChatImageURL = URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/chat-img")!

  // MARK: Ara
  static let araBackendURL = URL(string: "https://newara.dev.sparcs.org/api")!

  static let taxiBankNameList: [String] = [
    "NH농협",
    "KB국민",
    "카카오뱅크",
    "신한",
    "우리",
    "IBK기업",
    "하나",
    "토스뱅크",
    "새마을",
    "부산",
    "대구",
    "케이뱅크",
    "신협",
    "우체국",
    "SC제일",
    "경남",
    "수협",
    "광주",
    "전북",
    "저축은행",
    "씨티",
    "제주",
    "KDB산업",
  ]
}
