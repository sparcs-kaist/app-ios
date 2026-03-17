//
//  MapDiscoveryView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import SwiftUI

public struct MapDiscoveryView: View {
  @State private var viewModel = MapDiscoveryViewModel()
  @Namespace private var namespace

  @State private var showMap: Bool = false

  public init() { }

  public var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          ZStack {
            MapView(
              locations: viewModel.locations,
              selectedLocation: $viewModel.selectedLocation
            )
            .allowsHitTesting(false)
            .safeAreaInset(edge: .bottom, spacing: 0) {
              Rectangle()
                .foregroundStyle(.clear)
                .frame(height: 4)
            }
          }
          .frame(height: 280)
          .clipShape(.rect(cornerRadius: 28))
          .overlay {
            RoundedRectangle(cornerRadius: 28)
              .fill(Color.clear)
              .contentShape(.rect(cornerRadius: 28))
              .onTapGesture {
                showMap.toggle()
              }
          }
          .padding(.horizontal)
          .matchedTransitionSource(id: "MapExplorerViewSource", in: namespace)
        }
      }
      .navigationTitle("Discovery")
    }
    .fullScreenCover(isPresented: $showMap) {
      MapExplorerView(locations: viewModel.locations, selectedLocation: $viewModel.selectedLocation)
        .navigationTransition(.zoom(sourceID: "MapExplorerViewSource", in: namespace))
    }
  }
}


#Preview {
  MapDiscoveryView()
}
