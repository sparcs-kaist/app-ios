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

    let cleanedText = self.convertHtmlToPlainText(html: text) ?? ""

    if cleanedText.count <= 20 {
      return "This post is too short to summarize."
    }

    let session = LanguageModelSession(model: .default)
    session.prewarm()

    let prompt = """
      Summarise the following text in a \(tone) style, preserving key facts and subjects, names, dates, numbers, language.
      Limit the summary to \(maxWords) words.
      
      Text:
      \(cleanedText)
      """
    do {
      let response = try await session.respond(to: prompt)
      return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      return "Failed to summarise text. Please try again later."
    }
  }

  func convertHtmlToPlainText(html: String) -> String? {
    guard let data = html.data(using: .utf8) else {
      return nil
    }

    do {
      let attributedString = try NSAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue
        ],
        documentAttributes: nil
      )
      return attributedString.string
    } catch {
      print("Error converting HTML: \(error)")
      return nil
    }
  }
}

