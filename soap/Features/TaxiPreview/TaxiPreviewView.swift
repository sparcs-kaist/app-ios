//
//  TaxiPreviewView.swift
//  soap
//
//  Created by Soongyu Kwon on 01/11/2024.
//

import SwiftUI
import MapKit
import BuddyDomain

struct TaxiPreviewView: View {
  let room: TaxiRoom

  @State private var viewModel = TaxiPreviewViewModel()

  @Environment(\.dismiss) private var dismiss
  @State private var route: MKRoute?
  @State private var mapCamPos: MapCameraPosition = .automatic

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  var body: some View {
    VStack(spacing: 0) {
      Map(position: $mapCamPos) {
        Marker(
          room.source.title.localized(),
          systemImage: "location.fill",
          coordinate: room.source.coordinate
        )
        .tint(.accent)

        Marker(room.destination.title.localized(), coordinate: room.destination.coordinate)

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
      .frame(height: 200)
      .task {
        let calculatedRoute = try? await viewModel.calculateRoute(
          source: room.source.coordinate,
          destination: room.destination.coordinate
        )
        route = calculatedRoute
      }

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(room.title)
            .font(.callout)
            .fontWeight(.medium)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)

          Spacer()

          TaxiParticipantsIndicator(participants: room.participants.count, capacity: room.capacity)
        }

        RouteHeaderView(
          source: room.source.title.localized(),
          destination: room.destination.title.localized()
        )

        TaxiInfoSection(items: [
          .plain(
            label: String(localized: "Depart at"),
            value: room.departAt.formattedString
          ),
        ])

        Spacer()

        HStack {
          ShareLink(item: Constants.taxiInviteURL.appending(path: room.id), message: Text(LocalizedStringResource("🚕 Looking for someone to ride with on \(room.departAt.formattedString) from \(room.source.title) to \(room.destination.title)! 🚕"))) {
            Label("Share", systemImage: "square.and.arrow.up")
              .labelStyle(.iconOnly)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.glass)
          .buttonBorderShape(.circle)

          Button(action: {
            Task {
              do {
                try await viewModel.joinRoom(id: room.id)
                dismiss()
              } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
              }
            }
          }) {
            Group {
              if viewModel
                .isJoined(participants: room.participants) {
                Label("Joined", systemImage: "car.2.fill")
              } else if room.participants.count >= room.capacity || viewModel.isJoined(participants: room.participants) {
                Label("This group is full", systemImage: "car.2.fill")
              }
              else if room.isDeparted {
                Label("Already Departed", systemImage: "car.2.fill")
              }
              else if let count = viewModel.roomCount, count >= 5 {
                Label("Room Limit Reached", systemImage: "car.2.fill")
              }
              else if !viewModel.hasUserPaid {
                Label("Room Settlement Required", systemImage: "car.2.fill")
              }
              else {
                Label("Join", systemImage: "car.2.fill")
              }
            }
            .frame(maxWidth: .infinity, maxHeight: 44)
          }
          .buttonStyle(.glassProminent)
          .buttonBorderShape(.roundedRectangle(radius: 36))
          .disabled(isJoinButtonDisabled)
        }
      }
      .padding()
    }
    .alert("Error", isPresented: $showErrorAlert, actions: {
      Button("Okay", role: .close) { }
    }, message: {
      Text(errorMessage)
    })
    .ignoresSafeArea()
  }
  
  private var isJoinButtonDisabled: Bool {
    room.participants.count >= room.capacity
    || viewModel.isJoined(participants: room.participants)
    || room.isDeparted
    || (viewModel.roomCount ?? 5) >= 5 // if viewModel.roomCount is nil, fallback to the default value of 5 which disables join button
    || !viewModel.hasUserPaid
  }
}

#Preview {
  TaxiPreviewView(room: TaxiRoom.mockList[6])
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
