//
//  ListGlassSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 08/03/2026.
//

import SwiftUI

struct ListGlassSection<Content: View>: View {
  let header: Label<Text, Image>
  let content: () -> Content

  @Environment(\.colorScheme) private var colorScheme

  init(
    header: Label<Text, Image>,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.header = header
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        header
          .font(.title2)
          .fontWeight(.bold)
        Spacer()
      }

      VStack(alignment: .leading, spacing: 0) {
        content()
          .padding(.vertical)
      }
      .padding(.horizontal)
      .glassEffect(
        colorScheme == .light ? .identity : .regular.interactive(),
        in: .rect(cornerRadius: 28)
      )
      .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
    }
  }
}
