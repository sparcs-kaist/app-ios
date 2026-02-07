//
//  SearchContent.swift
//  soap
//
//  Created by 하정우 on 9/29/25.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

struct SearchContent<Element: Identifiable, Cell: View>: View {
  let results: [Element]
  @ViewBuilder let cell: (Element) -> Cell
  @State private var isLoadingMore: Bool = false
  var onLoadMore: (() async -> Void)? = nil
  
  var body: some View {
    if results.count == 0 {
      Text("No results")
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 100)
    }
    else {
      ForEach(Array(results.enumerated()), id: \.element.id) { index, data in
        Group {
          cell(data)
          if index != results.count - 1 { Divider() }
        }
        .onAppear {
          let thresholdIndex = Int(Double(results.count) * Constants.loadMoreThreshold)
          if index >= thresholdIndex {
            Task {
              isLoadingMore = true
              await onLoadMore?()
              isLoadingMore = false
            }
          }
        }
      }
      
      if isLoadingMore {
        HStack {
          Spacer()
          ProgressView().padding()
          Spacer()
        }
      }
    }
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 0.0) {
    SearchContent(results: Array(TaxiRoom.mockList[..<3])) {
      TaxiRoomCell(room: $0, withOutBackground: false)
    }
  }
}
