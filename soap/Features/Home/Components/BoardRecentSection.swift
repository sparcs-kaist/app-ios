//
//  BoardRecentSection.swift
//  soap
//
//  Created by Soongyu Kwon on 13/06/2025.
//

import SwiftUI

struct BoardRecentSection: View {
  var title: String

  var body: some View {
    VStack {
      HStack {
        Text(title)
          .font(.title2)
          .fontWeight(.bold)

        Button("Navigate", systemImage: "chevron.right") {
          
        }
          .font(.caption)
          .labelStyle(.iconOnly)
          .buttonBorderShape(.circle)
          .buttonStyle(.borderedProminent)
          .tint(Color.systemBackground)
          .foregroundStyle(.secondary)

        Spacer()
      }

      VStack(alignment: .leading, spacing: 8) {
        ForEach(0..<3) { _ in
          VStack(alignment: .leading) {
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
              .lineLimit(1)
            Text("Lorem ipsum\t13 min ago")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding()
      .background(Color.systemBackground)
      .clipShape(.rect(cornerRadius: 28))
    }
    .padding(.horizontal)  }
}

#Preview {
  ZStack {
    Color.secondarySystemBackground

    BoardRecentSection(title: "General")
  }
  .ignoresSafeArea()
}
