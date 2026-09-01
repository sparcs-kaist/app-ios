//
//  LectureDetailRow.swift
//  soap
//
//  Created by 하정우 on 9/30/25.
//

import SwiftUI

struct LectureDetailRow: View {
  let title: String
  let description: String
  
  var body: some View {
    HStack {
      Text(title)
        .foregroundStyle(.secondary)
        .font(.callout)
      Spacer()
      Text(description)
        .font(.callout)
        .multilineTextAlignment(.trailing)
    }
    .padding(.vertical, 4)
    Divider()
  }
}

#Preview {
    LectureDetailRow(title: "Title", description: "Description")
}
