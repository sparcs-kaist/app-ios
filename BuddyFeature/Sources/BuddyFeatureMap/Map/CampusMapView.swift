//
//  CampusMapView.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import BuddyDomain

public struct CampusMapView: View {
  @State private var viewModel: CampusMapViewModelProtocol

  public init(_ viewModel: CampusMapViewModelProtocol = CampusMapViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  public var body: some View {
    Group {
      switch viewModel.state {
      case .loading:
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .loaded:
        CampusExploreView(viewModel: viewModel)
      case .error(let message):
        ContentUnavailableView(
          String(localized: "Map Unavailable", bundle: .module),
          systemImage: "map",
          description: Text(message)
        )
      }
    }
    .scrollEdgeEffectStyle(.soft, for: .top)
    .task {
      guard viewModel.state == .loading else { return }
      await viewModel.fetchPlaces()
    }
  }
}

// MARK: - Previews

#Preview("Map") {
  NavigationStack {
    CampusMapView()
  }
}

#Preview("Place Card") {
  let viewModel = CampusMapViewModel()
  viewModel.places = CampusPlace.mockList
  viewModel.state = .loaded
  return ScrollView {
    PlaceDetailView(place: .mock, viewModel: viewModel, onClose: {})
      .padding()
  }
}
