//
//  MapExplorerView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/03/2026.
//

import SwiftUI
import BuddyDomain
import MapKit

struct MapExplorerView: View {
  let locations: [CampusLocation]
  @Binding var selectedLocation: CampusLocation?

  @Environment(\.dismiss) private var dismiss

  @State private var showActionSheet: Bool = true
  @State private var actionSheetDetent: PresentationDetent = .height(80)

  var body: some View {
    NavigationStack {
      MapView(locations: locations, selectedLocation: $selectedLocation)
        .safeAreaInset(edge: .bottom, spacing: 0) {
          Rectangle()
            .foregroundStyle(.clear)
            .frame(height: 64)
        }
        .sheet(isPresented: $showActionSheet) {
          MapDetailView(sheetDetent: $actionSheetDetent)
            .interactiveDismissDisabled()
            .presentationBackgroundInteraction(.enabled)
            .presentationDetents([.height(80), .fraction(0.6), .large], selection: $actionSheetDetent)
        }
        .onChange(of: showActionSheet) {
          showActionSheet = true
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Close", systemImage: "xmark") {
              dismiss()
            }
          }

          ToolbarItem(placement: .topBarTrailing) {
            Button("Location", systemImage: "location") {
            }
          }
        }
    }
  }
}
