//
//  FoundationModelsUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import Foundation
import FoundationModels
import BuddyDomain

public class FoundationModelsUseCase: FoundationModelsUseCaseProtocol {
  public var isAvailable: Bool {
    SystemLanguageModel.default.isAvailable
  }

  public func summarise(_ text: String, maxWords: Int = 120, tone: String = "concise") async -> String {
    guard case .available = SystemLanguageModel.default.availability else {
      return String(localized: "Model is currently unavailable. Please try again later.")
    }

    let cleanedText = text.convertFromHTML()

    if cleanedText.count <= 20 {
      return String(localized: "This content is too short to summarize.")
    }

    let session = LanguageModelSession(model: .default)
    session.prewarm()

    let prompt = String(localized: """
      Summarise the following content in a \(tone) style, preserving key facts and subjects, names, dates, numbers.
      Ignore greetings if that is not the main topic.
      Limit the summary to \(maxWords) words.
      
      Content:
      \(cleanedText)
      """)
    do {
      let response = try await session.respond(to: prompt)
      return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      return String(localized: "Failed to summarise text. Please try again later.")
    }
  }

  public init() {
    
  }
}

