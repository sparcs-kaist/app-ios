//
//  TaxiReport+Mockable.swift
//  soap
//
//  Created by 하정우 on 9/10/25.
//

import Foundation
import BuddyDomain

extension TaxiReport: Mockable {
  static var mock: TaxiReport {
    TaxiReport(
      id: "689cc4d514a641e076f953c0",
      creatorID: "689cc28b14a641e076f951ed",
      reportedUser: TaxiReportedUser(
        id: "test2eae3eea958ec71c2263",
        oid: "689cc28b14a641e076f951ed",
        nickname: "귀여운 운영체제 및 실험_c7360",
        profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        withdraw: false
      ),
      reason: .etcReason,
      etcDetails: "방에 초대되지 않은 사람을 데리고 옴",
      time: Date(),
      roomID: "689cc49c14a641e076f952bf"
    )
  }
  
  static var mockList: [TaxiReport] {
    [
      TaxiReport(
        id: "689cc6f914a641e076f9552c",
        creatorID: "689cc48f14a641e076f952a5",
        reportedUser: TaxiReportedUser(
          id: "test2eae3eea958ec71c2263",
          oid: "689cc28b14a641e076f951ed",
          nickname: "귀여운 운영체제 및 실험_c7360",
          profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
          withdraw: false
        ),
        reason: .etcReason,
        etcDetails: "방에 초대되지 않은 사람을 데리고 옴",
        time: Date(),
        roomID: "689cc49c14a641e076f952bf"
      ),
      TaxiReport(
        id: "689cc4d514a641e076f953c0",
        creatorID: "689cc28b14a641e076f951ed",
        reportedUser: TaxiReportedUser(
          id: "test2eae3eea958ec71c2263",
          oid: "689cc28b14a641e076f951ed",
          nickname: "귀여운 운영체제 및 실험_c7360",
          profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
          withdraw: false
        ),
        reason: .noSettlement,
        etcDetails: "",
        time: Date(),
        roomID: "689cc49c14a641e076f952bf"
      )
    ]
  }
}
