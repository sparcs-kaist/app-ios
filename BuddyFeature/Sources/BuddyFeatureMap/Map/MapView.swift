//
//  MapView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import SwiftUI
import BuddyDomain
import MapKit

struct MapView: View {
  @State private var position: MapCameraPosition = .region(
    MKCoordinateRegion(
      center: CLLocationCoordinate2D(
        latitude: 36.3725,
        longitude: 127.3624
      ),
      span: MKCoordinateSpan(
        latitudeDelta: 0.01,
        longitudeDelta: 0.01
      )
    )
  )

  @State private var locations: [CampusLocation] = CampusLocation.mockList

  @State private var selectedLocation: CampusLocation?
  @State private var showActionSheet: Bool = true
  @State private var actionSheetDetent: PresentationDetent = .height(80)

  var body: some View {
    Map(position: $position, selection: $selectedLocation) {
      UserAnnotation()

      ForEach(locations, id: \.id) { location in
        Marker(
          location.name,
          systemImage: location.category.symbol,
          coordinate: location.coordinate
        )
        .tint(location.category.color)
        .tag(location)
      }
    }
    .mapStyle(.standard(pointsOfInterest: .excludingAll))
    .mapControls {
      MapUserLocationButton()
    }
    .sheet(isPresented: $showActionSheet) {
      actionSheet
        .interactiveDismissDisabled()
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([.height(80), .height(350), .medium, .large], selection: $actionSheetDetent)
    }
  }

  var actionSheet: some View {
    VStack {

    }
  }
}

#Preview {
  MapView()
}
