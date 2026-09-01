//
//  LectureSummaryRow.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI

struct LectureSummaryRow: View {
  let title: String
  let description: String
  
  var body: some View {
    VStack(spacing: 8) {
      Text(title)
        .foregroundStyle(.tertiary)
        .font(.caption2)
        .fontWeight(.medium)
        .textCase(.uppercase)

      Text(description)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
    }
  }
}

#Preview {
  LectureSummaryRow(title: "Title", description: "Description")
}
