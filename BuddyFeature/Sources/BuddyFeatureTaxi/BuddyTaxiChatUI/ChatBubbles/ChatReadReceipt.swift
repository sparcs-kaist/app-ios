//
//  ChatReadReceipt.swift
//  soap
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import SwiftUI

struct ChatReadReceipt: View {
  let readCount: Int
  let showTime: Bool
  let time: Date
  let alignment: HorizontalAlignment

  var body: some View {
    VStack(alignment: alignment) {
      if readCount > 0 {
        Text("\(readCount)")
          .font(.caption2)
      }

      if showTime {
        Text(time, style: .time)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
}
