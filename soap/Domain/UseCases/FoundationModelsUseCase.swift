//
//  FoundationModelsUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import Foundation
import FoundationModels

@MainActor
protocol FoundationModelsUseCaseProtocol {
  var isAvailable: Bool { get }

  func summarise(_ text: String, maxWords: Int, tone: String) async -> String
}

class FoundationModelsUseCase: FoundationModelsUseCaseProtocol {
  var isAvailable: Bool {
    SystemLanguageModel.default.isAvailable
  }

  func summarise(_ text: String, maxWords: Int = 120, tone: String = "concise") async -> String {
    guard case .available = SystemLanguageModel.default.availability else {
      return "Model is currently unavailable. Please try again later."
    }

    let cleanedText = text.convertFromHTML()

    if cleanedText.count <= 20 {
      return "This post is too short to summarize."
    }

    let session = LanguageModelSession(model: .default)
    session.prewarm()

    let prompt = """
      Summarise the following post in a \(tone) style, preserving key facts and subjects, names, dates, numbers.
      Ignore greetings if that is not the main topic.
      Write the summary in the same language as the original post — do not translate it.
      Limit the summary to \(maxWords) words.
      
      Post:
      \(cleanedText)
      """
    do {
      let response = try await session.respond(to: prompt)
      return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      return "Failed to summarise text. Please try again later."
    }
  }
}

