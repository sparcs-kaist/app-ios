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
  let locations: [CampusLocation]
  @Binding private var selectedLocation: CampusLocation?

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

  init(
    locations: [CampusLocation],
    selectedLocation: Binding<CampusLocation?>
  ) {
    self.locations = locations
    self._selectedLocation = selectedLocation
  }

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
  }
}
