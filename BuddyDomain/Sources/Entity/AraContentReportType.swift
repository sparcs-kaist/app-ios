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
      String(localized: "Hate Speech")
    case .unauthorizedSales:
      String(localized: "Unauthorized Sales")
    case .spam:
      String(localized: "Spam")
    case .falseInformation:
      String(localized: "False Information")
    case .defamation:
      String(localized: "Defamation")
    case .other:
      String(localized: "Other")
    }
  }
}
