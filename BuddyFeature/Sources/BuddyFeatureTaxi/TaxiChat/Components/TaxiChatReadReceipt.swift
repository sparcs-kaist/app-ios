//
//  TaxiChatReadReceipt.swift
//  soap
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import SwiftUI

struct TaxiChatReadReceipt: View {
  let readCount: Int
  let showTimeLabel: Bool
  let time: String
  let alignment: HorizontalAlignment

  var body: some View {
    VStack(alignment: alignment) {
      if readCount > 0 {
        Text("\(readCount)")
          .font(.caption2)
      }

      if showTimeLabel {
        Text(time)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
}
