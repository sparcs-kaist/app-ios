//
//  CampusMapContent.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import MapKit
import BuddyDomain

extension MapCameraPosition {
  /// The whole main campus, Main Gate to the north dorms.
  static var kaist: MapCameraPosition {
    .region(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.3701, longitude: 127.3618),
        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
      )
    )
  }

  static func focused(on place: CampusPlace, distance: CLLocationDistance = 700) -> MapCameraPosition {
    .camera(MapCamera(centerCoordinate: place.coordinate, distance: distance))
  }

  /// Frames every one of `places`, with room around the outermost markers.
  static func fitting(_ places: [CampusPlace]) -> MapCameraPosition {
    guard let first = places.first else { return .kaist }
    let rect = places.reduce(MKMapRect.null) { rect, place in
      rect.union(MKMapRect(origin: MKMapPoint(place.coordinate), size: MKMapSize(width: 0, height: 0)))
    }
    let margin = MKMapPointsPerMeterAtLatitude(first.latitude) * 150
    return .rect(rect.insetBy(dx: -margin, dy: -margin))
  }
}

enum CampusMapStyle {
  case standard
  case satellite

  var mapStyle: MapStyle {
    switch self {
    case .standard: .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
    case .satellite: .hybrid(elevation: .realistic, pointsOfInterest: .excludingAll)
    }
  }
}

extension MapCameraBounds {
  /// Keeps the camera on campus: there is nothing to show beyond it.
  static var kaist: MapCameraBounds {
    MapCameraBounds(
      centerCoordinateBounds: MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.3701, longitude: 127.3618),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
      ),
      minimumDistance: 200,
      maximumDistance: 5000
    )
  }
}

/// The campus map: a marker per place, the OLEV route with its buses when OLEV is in focus, and a
/// stand-in for the user's location.
struct CampusMapContent: View {
  let viewModel: CampusMapViewModelProtocol
  let places: [CampusPlace]
  @Binding var position: MapCameraPosition
  @Binding var selection: String?
  /// Draws the OLEV route and its buses; only while OLEV is in focus, so it doesn't clutter the map.
  var showsOLEVRoute: Bool = false
  var interactionModes: MapInteractionModes = .all
  var style: CampusMapStyle = .standard
  /// Set when the host places the compass itself, beside its own controls.
  var scope: Namespace.ID?

  var body: some View {
    TimelineView(.periodic(from: .now, by: 10)) { context in
      Map(position: $position, bounds: .kaist, interactionModes: interactionModes, selection: $selection, scope: scope) {
        if showsOLEVRoute {
          let route = routeCoordinates
          // A white casing under the line, as Apple Maps draws transit lines, so it holds up over roads.
          MapPolyline(coordinates: route)
            .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
          MapPolyline(coordinates: route)
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))

          ForEach(viewModel.olevTimetable.buses(at: context.date)) { bus in
            Annotation(String(localized: "OLEV", bundle: .module), coordinate: coordinate(of: bus), anchor: .center) {
              Image(systemName: "bus.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue.gradient, in: .circle)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(radius: 2, y: 1)
            }
            .annotationTitles(.hidden)
          }
        }

        Annotation(String(localized: "My Location", bundle: .module), coordinate: viewModel.currentLocation.coordinate, anchor: .center) {
          CurrentLocationDot()
        }
        .annotationTitles(.hidden)

        ForEach(places) { place in
          place.marker
            .tint(place.category.tint)
            .tag(place.id)
        }
      }
      .mapStyle(style.mapStyle)
      .mapControls {
        if scope == nil {
          MapCompass()
        }
        MapScaleView()
      }
    }
  }

  /// The whole loop along the roads, with its corners rounded.
  private var routeCoordinates: [CLLocationCoordinate2D] {
    let points = viewModel.olevTimetable.stops.indices.flatMap(leg)
    // Legs meet at each stop, so drop the repeated point where one ends and the next begins.
    let path = points.reduce(into: [CLLocationCoordinate2D]()) { path, point in
      if let last = path.last, last.distance(to: point) < 1 { return }
      path.append(point)
    }
    return path.roundingCorners(radius: 15)
  }

  /// The road from stop `index` to the next, or a straight line where the timetable has no path.
  private func leg(_ index: Int) -> [CLLocationCoordinate2D] {
    let stops = viewModel.olevTimetable.stops
    let path = stops[index].path.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    if path.count > 1 { return path }

    return [stops[index], stops[(index + 1) % stops.count]].compactMap { viewModel.place(id: $0.placeID)?.coordinate }
  }

  /// Places a bus the right distance along the road between its two stops.
  private func coordinate(of bus: OLEVBusPosition) -> CLLocationCoordinate2D {
    guard viewModel.olevTimetable.stops.indices.contains(bus.fromStopIndex) else {
      return viewModel.currentLocation.coordinate
    }
    let points = leg(bus.fromStopIndex)
    guard let first = points.first else { return viewModel.currentLocation.coordinate }

    let lengths = zip(points, points.dropFirst()).map { $0.distance(to: $1) }
    var remaining = lengths.reduce(0, +) * bus.fraction
    for (index, length) in lengths.enumerated() {
      guard remaining > length, index < lengths.count - 1 else {
        return points[index].moved(toward: points[index + 1], by: length > 0 ? min(remaining / length, 1) : 0)
      }
      remaining -= length
    }
    return first
  }
}

private extension CLLocationCoordinate2D {
  func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
    CLLocation(latitude: latitude, longitude: longitude)
      .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
  }

  func moved(toward other: CLLocationCoordinate2D, by fraction: Double) -> CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: latitude + (other.latitude - latitude) * fraction,
      longitude: longitude + (other.longitude - longitude) * fraction
    )
  }
}

private extension Array where Element == CLLocationCoordinate2D {
  /// Swaps each corner for a short curve so the line turns smoothly instead of kinking at every
  /// junction. `radius` caps how far back from the corner the curve starts, which keeps it on the
  /// road; the path is treated as closed, so the corner where it rejoins its start is rounded too.
  func roundingCorners(radius: CLLocationDistance, steps: Int = 6) -> [CLLocationCoordinate2D] {
    guard count > 2 else { return self }
    var rounded: [CLLocationCoordinate2D] = []

    for index in indices {
      let corner = self[index]
      let previous = self[(index - 1 + count) % count], next = self[(index + 1) % count]
      let inLength = corner.distance(to: previous), outLength = corner.distance(to: next)
      guard inLength > 0, outLength > 0 else { continue }

      // Where the curve leaves the incoming leg and joins the outgoing one.
      let start = corner.moved(toward: previous, by: Swift.min(radius / inLength, 0.5))
      let end = corner.moved(toward: next, by: Swift.min(radius / outLength, 0.5))
      // A quadratic Bézier with the corner as its control point.
      for step in 0...steps {
        let t = Double(step) / Double(steps)
        let a = start.moved(toward: corner, by: t), b = corner.moved(toward: end, by: t)
        rounded.append(a.moved(toward: b, by: t))
      }
    }
    return rounded + rounded.prefix(1)
  }
}

/// The blue dot, drawn by hand because the mock location isn't the device's.
struct CurrentLocationDot: View {
  var body: some View {
    Circle()
      .fill(Color.blue)
      .frame(width: 16, height: 16)
      .overlay(Circle().stroke(.white, lineWidth: 3))
      .background(Circle().fill(Color.blue.opacity(0.18)).frame(width: 44, height: 44))
      .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
  }
}
