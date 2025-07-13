//
//  TaxiPreviewView.swift
//  soap
//
//  Created by Soongyu Kwon on 01/11/2024.
//

import SwiftUI
import MapKit

struct TaxiPreviewView: View {
  let room: TaxiRoom
  @State private var route: MKRoute?
  @State private var mapCamPos: MapCameraPosition = .automatic

  var body: some View {
    VStack(spacing: 0) {
      Map(position: $mapCamPos) {
        Marker(
          room.from.title.localized(),
          systemImage: "location.fill",
          coordinate: room.from.coordinate
        )
        .tint(.accent)

        Marker(room.to.title.localized(), coordinate: room.to.coordinate)

        if let route {
          let strokeStyle = StrokeStyle(
            lineWidth: 5,
            lineCap: .round,
            lineJoin: .round
          )

          MapPolyline(route.polyline)
            .stroke(.accent, style: strokeStyle)
        }
      }
      .disabled(true)
      .frame(height: 220)
      .onAppear {
        calculateRoute(from: room.from.coordinate, to: room.to.coordinate)
      }

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(room.title)
            .font(.callout)
            .fontWeight(.medium)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)

          Spacer()

          HStack(spacing: 4) {
            Text("\(room.participants.count)/\(room.capacity)")
            Image(systemName: "person.2")
          }
          .font(.footnote)
          .foregroundStyle(.green)
          .padding(4)
          .background(.green.opacity(0.1))
          .clipShape(.rect(cornerRadius: 4))
        }

        RouteHeaderView(
          origin: room.from.title.localized(),
          destination: room.to.title.localized()
        )

        TaxiInfoSection(items: [
          .plain(
            label: "Depart at",
            value: room.departAt.formattedString
          ),
        ])

        Spacer()

        HStack {
          Button(action: {
            // Share action
          }) {
            Label("Share", systemImage: "square.and.arrow.up")
              .labelStyle(.iconOnly)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.bordered)
          .buttonBorderShape(.circle)

          Button(action: {
            // Join action
          }) {
            Label("Join", systemImage: "car.2.fill")
              .frame(maxWidth: .infinity, maxHeight: 44)
          }
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.roundedRectangle(radius: 36))
        }
      }
      .padding()
    }
    .ignoresSafeArea()
  }

  private func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
    let request = MKDirections.Request()
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    request.source = MKMapItem(location: fromLocation, address: nil)
    request.destination = MKMapItem(location: toLocation, address: nil)
    request.transportType = .automobile
    let directions = MKDirections(request: request)
    directions.calculate { response, error in
      guard let route = response?.routes.first else {
        return
      }
      self.route = route
      mapCamPos = .region(
        MKCoordinateRegion(
          center: CLLocationCoordinate2D(
            latitude: (from.latitude + to.latitude) / 2 + 0.005,
            longitude: (from.longitude + to.longitude) / 2
          ),
          span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0)
        )
      )
    }
  }
}

extension TaxiLocationOld {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

#Preview {
  struct TaxiPreviewWrapper: View {
    @State private var roomInfo: RoomInfo = .mock
    var body: some View {
      TaxiPreviewView(room: TaxiRoom.mockList[6])
    }
  }
  return TaxiPreviewWrapper()
}


#Preview {
  @Previewable @State var showSheet: Bool = true
  ZStack {

  }
  .sheet(isPresented: $showSheet) {
    TaxiPreviewView(room: TaxiRoom.mockList[6])
      .presentationDragIndicator(.visible)
      .presentationDetents([.height(400), .height(500)])
  }
}
