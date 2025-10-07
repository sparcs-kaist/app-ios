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
      String(localized: "Extreme Politics", bundle: .module)
    case .abusiveLanguage:
      String(localized: "Offensive Language", bundle: .module)
    case .pornography:
      String(localized: "Sexually Explicit Content", bundle: .module)
    case .spam:
      String(localized: "Spam", bundle: .module)
    case .impersonationFraud:
      String(localized: "Impersonation/Fraud", bundle: .module)
    case .commercialAd:
      String(localized: "Advertisement", bundle: .module)
    }
  }
}
