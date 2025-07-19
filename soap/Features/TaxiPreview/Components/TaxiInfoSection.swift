//
//  TaxiInfoSection.swift
//  soap
//
//  Created by Minjae Kim on 5/4/25.
//

import SwiftUI

struct TaxiInfoSection: View {
  let items: [TaxiInfoItem]

  var body: some View {
    VStack(spacing: 16) {
      ForEach(items) { item in
        switch item {
        case .plain(let label, let value):
          InfoRow(label: label, value: value)
        case .withIcon(let label, let value, let systemImage):
          HStack {
            InfoRow(label: label, value: value)
            Image(systemName: systemImage)
              .foregroundColor(.gray)
          }
        }
      }
    }
  }
}

#Preview {
  TaxiInfoSection(items: [
    .plain(label: "Test Label 1", value: "Test Value 1"),
    .withIcon(label: "Test Label 2", value: "Test Value 2", systemImage: "chevron.right")
  ])
  .padding()
}

