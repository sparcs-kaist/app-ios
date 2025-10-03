//
//  FeedReportType.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import Foundation

enum FeedReportType: String, CaseIterable, Identifiable {
  var id: Self { self }
  
  case extremePolitics = "EXTREME_POLITICS"
  case pornography = "PORNOGRAPHY"
  case spam = "SPAM"
  case abusiveLanguage = "ABUSIVE_LANGUAGE"
  case impersonationFraud = "IMPERSONATION_FRAUD"
  case commercialAd = "COMMERCIAL_AD"
}

extension FeedReportType {
  var prettyString: String {
    switch self {
    case .extremePolitics:
      "Extreme Politics"
    case .abusiveLanguage:
      "Abusive Language"
    case .pornography:
      "Pornography"
    case .spam:
      "Spam"
    case .impersonationFraud:
      "Impersonation or Fraud"
    case .commercialAd:
      "Commercial Ad"
    }
  }
}
