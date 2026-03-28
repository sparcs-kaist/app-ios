//
//  AraContentReportType.swift
//  soap
//
//  Created by Soongyu Kwon on 12/08/2025.
//

import Foundation

public enum AraContentReportType: String, Sendable, CaseIterable {
  case hateSpeech = "hate_speech"
  case unauthorizedSales = "unauthorized_sales_articles"
  case spam = "spam"
  case falseInformation = "fake_information"
  case defamation = "defamation"
  case other = "other"
}

extension AraContentReportType {
  public var prettyString: String {
    switch self {
    case .hateSpeech:
      String(localized: "Hate Speech", bundle: .module)
    case .unauthorizedSales:
      String(localized: "Unauthorized Sales", bundle: .module)
    case .spam:
      String(localized: "Spam", bundle: .module)
    case .falseInformation:
      String(localized: "False Information", bundle: .module)
    case .defamation:
      String(localized: "Defamation", bundle: .module)
    case .other:
      String(localized: "Other", bundle: .module)
    }
  }
}
