//
//  SummarisationView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import Foundation
import SwiftUI

public struct SummarisationView: View {
  let text: String
  /// Still being written, though some text may already have arrived.
  let isSummarising: Bool
  private var isLoading: Bool { text.isEmpty }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "text.append")

        Text(isLoading || isSummarising
          ? String(localized: "Summarising...", bundle: .module)
          : String(localized: "Summary", bundle: .module))
          .textCase(.uppercase)
          .contentTransition(.numericText())

        Spacer()
      }
      .font(.footnote)
      .fontWeight(.semibold)
      .foregroundStyle(.secondary)

      Group {
        if isLoading {
          Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam posuere pharetra aliquam. Aliquam nec mauris aliquam, efficitur sapien venenatis, feugiat purus.")
            .redacted(reason: .placeholder)
        } else {
          Text(text)
        }
      }
      .transition(.opacity)

      Text("**Note:** May contain errors, please double-check facts.", bundle: .module)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .animation(.spring, value: text)
  }

  /// - Parameter isSummarising: Whether `text` is still being written. Empty
  ///   text always reads as still being written.
  public init(text: String, isSummarising: Bool = false) {
    self.text = text
    self.isSummarising = isSummarising
  }
}

#Preview {
  VStack {
    SummarisationView(text: "")
      .padding()
      .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
      .padding()

    SummarisationView(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam posuere pharetra aliquam. Aliquam nec mauris aliquam, efficitur")
      .padding()
      .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
      .padding()
  }
}
