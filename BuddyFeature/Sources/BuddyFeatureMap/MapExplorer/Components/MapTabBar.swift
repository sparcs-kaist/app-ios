//
//  MapTabBar.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 18/03/2026.
//

import SwiftUI
import BuddyDomain

struct MapTabBar: View {
  @Binding var selection: MapTab

  var body: some View {
    HStack(spacing: 0) {
      ForEach(MapTab.allCases, id: \.rawValue) { tab in
        VStack(spacing: 4) {
          Image(systemName: tab.symbol)
            .font(.title3)
            .symbolVariant(.fill)

          Text(tab.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
        }
        .foregroundStyle(selection == tab ? Color.accentColor : .primary)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture {
          selection = tab
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 10)
    .padding(.bottom, 12)
  }
}
