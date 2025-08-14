//
//  SummarisationView.swift
//  soap
//
//  Created by Soongyu Kwon on 14/08/2025.
//

import SwiftUI

struct SummarisationView: View {
  let text: String
  private var isLoading: Bool { text.isEmpty }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(isLoading ? "Summarising..." : "Summary")
        .textCase(.uppercase)
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .contentTransition(.numericText())

      Group {
        if isLoading {
          Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam posuere pharetra aliquam. Aliquam nec mauris aliquam, efficitur sapien venenatis, feugiat purus.")
            .redacted(reason: .placeholder)
        } else {
          Text(text)
        }
      }
      .transition(.opacity)

      HStack {
        Text("**Note:** May contain errors, please double-check facts.")
          .font(.footnote)
          .foregroundStyle(.secondary)

        Spacer()
      }
    }
    .animation(.spring, value: text)
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
