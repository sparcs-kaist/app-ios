//
//  MapDetailView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/03/2026.
//

import SwiftUI
import BuddyDomain

struct MapDetailView: View {
  @Binding var sheetDetent: PresentationDetent
  @State var selectedTab: MapTab = .nearby

  var body: some View {
    GeometryReader {
      let safeArea = $0.safeAreaInsets
      let bottomPadding = safeArea.bottom / 5

      VStack(spacing: 0) {
        Group {
          switch selectedTab {
          case .nearby:
            NearbyView()
          case .classrooms:
            ClassroomsView()
          case .olev:
            OLEVView()
          case .search:
            SearchView()
          }
        }
        .padding(.top, 4)
        .padding(.horizontal, 4)

        MapTabBar(selection: $selectedTab)
          .padding(.bottom, bottomPadding)
      }
      .ignoresSafeArea(.all, edges: .bottom)
      .onChange(of: selectedTab) {
        print(sheetDetent)
        if sheetDetent == .height(80) {
          sheetDetent = .fraction(0.6)
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var showSheet = true
  @Previewable @State var sheetDetent: PresentationDetent = .height(80)

  VStack {

  }
  .sheet(isPresented: $showSheet) {
    MapDetailView(sheetDetent: $sheetDetent)
      .presentationDetents([.height(80), .fraction(0.6), .large], selection: $sheetDetent)
      .presentationDragIndicator(.visible)
      .presentationBackgroundInteraction(.enabled)
  }
}

