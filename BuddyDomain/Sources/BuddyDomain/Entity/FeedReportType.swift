//
//  FeedReportType.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import Foundation

public enum FeedReportType: String, CaseIterable, Identifiable, Sendable {
  public var id: Self { self }

  case extremePolitics = "EXTREME_POLITICS"
  case pornography = "PORNOGRAPHY"
  case spam = "SPAM"
  case abusiveLanguage = "ABUSIVE_LANGUAGE"
  case impersonationFraud = "IMPERSONATION_FRAUD"
  case commercialAd = "COMMERCIAL_AD"
}

extension FeedReportType {
  public var description: String {
    switch self {
    case .extremePolitics:
      String(localized: "Extreme Politics")
    case .abusiveLanguage:
      String(localized: "Offensive Language")
    case .pornography:
      String(localized: "Sexually Explicit Content")
    case .spam:
      String(localized: "Spam")
    case .impersonationFraud:
      String(localized: "Impersonation/Fraud")
    case .commercialAd:
      String(localized: "Advertisement")
    }
  }
}
