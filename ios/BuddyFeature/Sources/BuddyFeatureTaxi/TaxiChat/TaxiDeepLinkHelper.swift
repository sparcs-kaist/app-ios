//
//  TaxiDeepLinkHelper.swift
//  soap
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import UIKit
import BuddyDomain

enum TaxiDeepLinkHelper {
  static func kakaoTURL(source: TaxiLocation, destination: TaxiLocation) -> URL? {
    URL(string: "kakaot://taxi/set?dest_lng=\(destination.longitude)&dest_lat=\(destination.latitude)&origin_lng=\(source.longitude)&origin_lat=\(source.latitude)")
  }

  static func uberURL(source: TaxiLocation, destination: TaxiLocation) -> URL? {
    URL(string: "uber://?action=setPickup&client_id=a&&pickup[latitude]=\(source.latitude)&pickup[longitude]=\(source.longitude)&&dropoff[latitude]=\(destination.latitude)&dropoff[longitude]=\(destination.longitude)")
  }

  static func kakaoPayURL(account: String?) -> URL? {
    if let account {
      let accountNo = String(account.split(separator: " ").last ?? "")
      UIPasteboard.general.string = accountNo
    }
    return URL(string: "kakaotalk://kakaopay/money/to/bank")
  }

  static func tossURL(account: String?) -> URL? {
    let bankName = String(account?.split(separator: " ").first ?? "")
    let bankCode = Constants.taxiBankCodeMap[bankName] ?? ""
    let accountNo = String(account?.split(separator: " ").last ?? "")
    return URL(string: "supertoss://send?bankCode=\(bankCode)&accountNo=\(accountNo)")
  }
}
