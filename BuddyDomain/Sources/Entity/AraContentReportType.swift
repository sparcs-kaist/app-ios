//
//  AraContentReportType.swift
//  soap
//
//  Created by Soongyu Kwon on 12/08/2025.
//

import Foundation

public enum AraContentReportType: String, Sendable {
  case hateSpeech = "hate_speech"
  case unauthorizedSales = "unauthorized_sales_articles"
  case spam = "spam"
  case falseInformation = "fake_information"
  case defamation = "defamation"
  case other = "other"
}
