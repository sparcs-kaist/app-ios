//
//  BoardsSection.swift
//  soap
//
//  Created by Soongyu Kwon on 13/06/2025.
//

import SwiftUI

struct BoardsSection: View {
  var body: some View {
    VStack {
      HStack {
        Text("Boards")
          .font(.title2)
          .fontWeight(.bold)

        Button("Navigate", systemImage: "chevron.right") { }
          .font(.caption)
          .labelStyle(.iconOnly)
          .buttonBorderShape(.circle)
          .buttonStyle(.borderedProminent)
          .tint(Color.systemBackground)
          .foregroundStyle(.secondary)

        Spacer()
      }

      VStack(alignment: .leading, spacing: 8) {
        ForEach(0..<7) { _ in
          HStack(alignment: .bottom, spacing: 16) {
            Text("Board")
              .fontWeight(.medium)
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
              .lineLimit(1)
          }
        }
      }
      .padding()
      .background(Color.systemBackground)
      .clipShape(.rect(cornerRadius: 28))
    }
    .padding(.horizontal)
  }
}

#Preview {
  ZStack {
    Color.secondarySystemBackground

    BoardsSection()
  }
  .ignoresSafeArea()
}

