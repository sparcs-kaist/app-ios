//
//  SettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 7/29/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class SettingsViewModel {
  // MARK: - Mock data
  // TODO: implement API call & data structures
  var araAllowSexualPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araBlockedUsers: [String] = ["유능한 시조새_0b4c"]
  var taxiBankName: String = "카카오뱅크"
  var taxiBankNumber: String = "7777-02-3456789"
  var otlMajor: Int = 1
  
  // MARK: - Properties
  let taxiBankNameList: [String] = [
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
  ];
  
  
}
