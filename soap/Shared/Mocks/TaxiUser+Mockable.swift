//
//  TaxiUser+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import Foundation
import BuddyDomain

extension TaxiUser: Mockable {
  static var mock: TaxiUser {
    TaxiUser(
      id: "mock-taxi-user-id",
      oid: "user1",
      name: "Alice Kim",
      nickname: "Alice",
      phoneNumber: "+82-10-1234-5678",
      email: "alice@example.com",
      withdraw: false,
      ban: false,
      agreeOnTermsOfService: true,
      joinedAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
      profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
      account: "카카오뱅크 3333-01-1234567"
    )
  }
  
  static var mockList: [TaxiUser] {
    [
      TaxiUser(
        id: "mock-taxi-user-1",
        oid: "user1",
        name: "Alice Kim",
        nickname: "Alice",
        phoneNumber: "+82-10-1234-5678",
        email: "alice@example.com",
        withdraw: false,
        ban: false,
        agreeOnTermsOfService: true,
        joinedAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
        profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        account: "카카오뱅크 3333-01-1234567"
      ),
      TaxiUser(
        id: "mock-taxi-user-2",
        oid: "user2",
        name: "Bob Lee",
        nickname: "Bob",
        phoneNumber: "+82-10-9876-5432",
        email: "bob@example.com",
        withdraw: false,
        ban: false,
        agreeOnTermsOfService: true,
        joinedAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
        profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/GooseOTL.png"),
        account: "신한은행 110-123-456789"
      ),
      TaxiUser(
        id: "mock-taxi-user-3",
        oid: "user3",
        name: "Charlie Park",
        nickname: "Charlie",
        phoneNumber: "+82-10-5555-6666",
        email: "charlie@example.com",
        withdraw: false,
        ban: false,
        agreeOnTermsOfService: true,
        joinedAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
        profileImageURL: URL(string: "https://sparcs-taxi-dev.s3.ap-northeast-2.amazonaws.com/profile-img/default/NupjukOTL.png"),
        account: "국민은행 123456-04-123456"
      )
    ]
  }
} 
