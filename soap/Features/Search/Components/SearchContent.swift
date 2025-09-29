//
//  SearchContent.swift
//  soap
//
//  Created by 하정우 on 9/29/25.
//

import SwiftUI

struct SearchContent<Element: Identifiable, Cell: View>: View {
  let results: [Element]
  @ViewBuilder let cell: (Element) -> Cell
  
  var body: some View {
    if results.count == 0 {
      Text("No results")
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 100)
    }
    else {
      ForEach(results) {
        cell($0)
        Divider()
      }
    }
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 0.0) {
    SearchContent(results: Array(TaxiRoom.mockList[..<3])) {
      TaxiRoomCell(room: $0)
    }
  }
}
