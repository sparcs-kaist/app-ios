//
//  TaxiPreviewView.swift
//  soap
//
//  Created by Soongyu Kwon on 01/11/2024.
//

import SwiftUI
import SmoothGradient
import MapKit

struct TaxiPreviewView: View {
    @State private var route: MKRoute?
    @State private var mapCamPos: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (36.37319 + 36.332327) / 2,
                longitude: (127.35948 + 127.434390) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    )
    
    private let startingPoint = CLLocationCoordinate2D(
        latitude: 36.37319,
        longitude: 127.35948
    )
    
    private let destinationCoordinates = CLLocationCoordinate2D(
        latitude: 36.332327,
        longitude: 127.434390
    )
    
    let strokeStyle = StrokeStyle(
        lineWidth: 5,
        lineCap: .round,
        lineJoin: .round
    )
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
            Map(position: $mapCamPos, interactionModes: []) {
                Marker("KAIST", systemImage: "car.fill", coordinate: startingPoint)
                    .tint(.accent)
                
                Marker("Daejeon Station", coordinate: destinationCoordinates)
                    .tint(.red)
                
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.accent, style: strokeStyle)
                }
            }
            .offset(y: -75)
            .onAppear() {
                calculateRoute()
            }
            
            VStack(spacing: 0) {
                SmoothLinearGradient(
                    from: .black,
                    to: .clear,
                    startPoint: .bottom,
                    endPoint: .top,
                    curve: .easeInOut
                )
                Color.black
                    .frame(height: 75)
            }
            
            VStack(alignment: .leading) {
                Group {
                    HStack {
                        Text("KAIST")
                        Image(systemName: "arrow.right")
                    }
                    
//                    Text("Daejeon Station")
                    Label("Daejeon Station", systemImage: "mappin.and.ellipse")
                }
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.bold)
                
                HStack {
                    HStack(spacing: 4) {
                        Text("2/4")
                        Image(systemName: "person.2")
                    }
                    .font(.footnote)
                    .foregroundStyle(.green)
                    
                    Text("Tommorow at 10:00")
                        .foregroundColor(.white.opacity(0.55))
                }
                
                HStack {
                    Button(action: {
                        // cancel
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    
                    Button(action: {
                        // join
                    }) {
                        Label("Join", systemImage: "car.2.fill")
                            .frame(maxWidth: .infinity, maxHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 36))
                    
                }
            }.padding([.horizontal, .bottom], 20)
        }.ignoresSafeArea()
        
    }
    
    private func calculateRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinates))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                return
            }
            
            self.route = route
        }
    }
}

#Preview {
    TaxiPreviewView()
}
