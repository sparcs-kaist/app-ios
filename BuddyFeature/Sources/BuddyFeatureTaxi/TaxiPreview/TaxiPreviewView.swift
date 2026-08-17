//
//  TaxiPreviewView.swift
//  soap
//
//  Created by Soongyu Kwon on 01/11/2024.
//

import Foundation
import SwiftUI
import MapKit
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiPreviewView")

public struct TaxiPreviewView: View {
  let room: TaxiRoom

  @State private var viewModel = TaxiPreviewViewModel()

  @Environment(\.dismiss) private var dismiss
  /// Set only when this is presented as a macOS card rather than a sheet, where
  /// `dismiss()` has nothing of ours to close. See `DismissableCard`.
  @Environment(\.buddyCardDismiss) private var cardDismiss
  @State private var route: MKRoute?
  @State private var mapCamPos: MapCameraPosition = .automatic

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  public init(room: TaxiRoom) {
    self.room = room
  }

  public var body: some View {
    VStack(spacing: 0) {
      Map(position: $mapCamPos) {
        Marker(
          room.source.title.localized(),
          systemImage: "location.fill",
          coordinate: room.source.coordinate
        )
        .tint(.indigo)

        Marker(room.destination.title.localized(), coordinate: room.destination.coordinate)

        if let route {
          let strokeStyle = StrokeStyle(
            lineWidth: 5,
            lineCap: .round,
            lineJoin: .round
          )

          MapPolyline(route.polyline)
            .stroke(.indigo, style: strokeStyle)
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
            label: String(localized: "Depart at", bundle: .module),
            value: room.departAt.formattedString
          ),
        ])

        Spacer()

        HStack {
          ShareLink(item: Constants.taxiInviteURL.appending(path: room.id), message: Text("🚕 Looking for someone to ride with on \(room.departAt.formattedString) from \(room.source.title) to \(room.destination.title)! 🚕", bundle: .module)) {
            Label(String(localized: "Share", bundle: .module), systemImage: "square.and.arrow.up")
              .labelStyle(.iconOnly)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.glass)
          .buttonBorderShape(.circle)

          Button(action: {
            Task {
              do {
                try await viewModel.joinRoom(id: room.id)
                close()
              } catch {
                logger.error("Failed to join room: \(error.localizedDescription, privacy: .public)")
                errorMessage = error.localizedDescription
                showErrorAlert = true
              }
            }
          }) {
            Group {
              if viewModel
                .isJoined(participants: room.participants) {
                Label(String(localized: "Joined", bundle: .module), systemImage: "car.2.fill")
              } else if room.participants.count >= room.capacity || viewModel.isJoined(participants: room.participants) {
                Label(String(localized: "This group is full", bundle: .module), systemImage: "car.2.fill")
              }
              else if room.isDeparted {
                Label(String(localized: "Already Departed", bundle: .module), systemImage: "car.2.fill")
              }
              else if viewModel.blockStatus == .tooManyRooms {
                Label(String(localized: "Room Limit Reached", bundle: .module), systemImage: "car.2.fill")
              }
              else if viewModel.blockStatus == .notPaid {
                Label(String(localized: "Room Settlement Required", bundle: .module), systemImage: "car.2.fill")
              }
              else {
                Label(String(localized: "Join", bundle: .module), systemImage: "car.2.fill")
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
    .alert(String(localized: "Error", bundle: .module), isPresented: $showErrorAlert, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text(errorMessage)
    })
    .ignoresSafeArea()
    #if os(macOS)
    // There is no swipe to fall back on here, and unlike the composers this screen has
    // no toolbar to hang a Cancel button off. Leading edge because that is where every
    // other sheet in the app puts its close button, and because MapKit draws its own
    // controls in the trailing corner.
    .overlay(alignment: .topLeading) {
      Button(String(localized: "Close", bundle: .module), systemImage: "xmark", role: .close) {
        close()
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.glass)
      .buttonBorderShape(.circle)
      .keyboardShortcut(.cancelAction)
      .padding(12)
    }
    #endif
    .analyticsScreen(name: "Taxi Preview", class: String(describing: Self.self))
  }

  /// Closes whichever presentation this is in: the macOS card publishes its own action
  /// because `dismiss()` cannot reach it, and on iOS that action is nil.
  private func close() {
    if let cardDismiss {
      cardDismiss()
    } else {
      dismiss()
    }
  }

  private var isJoinButtonDisabled: Bool {
    room.participants.count >= room.capacity
    || viewModel.isJoined(participants: room.participants)
    || room.isDeparted
    || viewModel.blockStatus != .allow
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
