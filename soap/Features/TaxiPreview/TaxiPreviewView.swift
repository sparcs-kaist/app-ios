//
//  TaxiPreviewView.swift
//  soap
//
//  Created by Soongyu Kwon on 01/11/2024.
//

import SwiftUI
import MapKit

struct TaxiPreviewView: View {
    @Binding var roomInfo: RoomInfo
    @State private var route: MKRoute?
    @State private var mapCamPos: MapCameraPosition = .automatic
    let strokeStyle = StrokeStyle(
        lineWidth: 5,
        lineCap: .round,
        lineJoin: .round
    )
    
    var body: some View {
        VStack(spacing: 0) {
            Map(position: $mapCamPos) {
                Marker(roomInfo.origin.title, systemImage: "car.fill", coordinate: roomInfo.origin.coordinate).tint(.blue)
                Marker(roomInfo.destination.title, coordinate: roomInfo.destination.coordinate).tint(.red)
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(Color.blue, style: strokeStyle)
                }
            }
            .frame(height: 200)
            .onAppear {
                calculateRoute(from: roomInfo.origin.coordinate, to: roomInfo.destination.coordinate)
            }
            
            VStack(alignment: .leading, spacing: 24) {
                RouteHeaderView(
                    origin: roomInfo.origin.title,
                    destination: roomInfo.destination.title
                )
                .padding(.top, 24)
                
                TaxiInfoSection(items: [
                    .plain(
                        label: "Departure Date",
                        value: roomInfo.departureTime.DateString
                    ),
                    .plain(
                         label: "Departure Time",
                         value: roomInfo.departureTime.TimeString
                    )
                ])
                .padding(.bottom, 24)
                
                /*
                 if let route {
                    TaxiInfoSection(items: [
                        .plain(
                            label: "Distance",
                            value: "\(String(format: "%.2f", route.distance / 1000)) km"
                        ),
                        .plain(
                             label: "Estimate Arrival Time",
                             value: roomInfo.departureTime
                                 .addingTimeInterval(route.expectedTravelTime)
                                 .TimeString
                        )
                    ])
                    .padding(.bottom, 24)
                } else {
                    Text("Calculating Route...")
                        .foregroundColor(.gray)
                        .padding(.bottom, 24)
                }
                 */
                
                TaxiInfoSection(items: [
                    .plain(label: "Room Name", value: roomInfo.name),
                    .withIcon(
                        label: "Participants",
                        value: "\(roomInfo.occupancy)/\(roomInfo.capacity)",
                        systemImage: "chevron.right"
                    )
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
                .padding(.top, 10)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
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
                        latitude: (from.latitude + to.latitude) / 2,
                        longitude: (from.longitude + to.longitude) / 2
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                )
            )
        }
    }
}

extension TaxiLocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    struct TaxiPreviewWrapper: View {
        @State private var roomInfo: RoomInfo = .mock
        var body: some View {
            TaxiPreviewView(roomInfo: $roomInfo)
        }
    }
    return TaxiPreviewWrapper()
}
