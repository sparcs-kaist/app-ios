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
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.colorScheme) private var colorScheme
  @State private var route: MKRoute?
  /// Whether no route could be found, so the placeholder held for its figures can go.
  @State private var routeFailed = false
  @State private var mapCamPos: MapCameraPosition = .automatic
  /// Height of the details panel, so the map frames the route in the part left above it.
  @State private var detailsHeight: CGFloat = 0
  /// Width of the details column beside the map on a short screen, side bar included, so the map
  /// frames the route in the part left beside it.
  @State private var detailsWidth: CGFloat = 0

  @State private var showErrorAlert: Bool = false
  @State private var errorMessage: String = ""

  /// Called with the room once you have joined it, so whoever showed the preview can open its
  /// chat; the preview closes itself first.
  private let onJoin: ((TaxiRoom) -> Void)?

  public init(room: TaxiRoom, onJoin: ((TaxiRoom) -> Void)? = nil) {
    self.room = room
    self.onJoin = onJoin
  }

  public var body: some View {
    NavigationStack {
      layout
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button(role: .close) {
              dismiss()
            }
          }
        }
    }
    .alert(String(localized: "Error", bundle: .module), isPresented: $showErrorAlert, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text(errorMessage)
    })
    // Plain white or black rather than the default sheet material, so the map fades into a
    // solid panel; the map itself follows the appearance, light or dark.
    .presentationBackground(sheetColor)
    .task {
      mapCamPos = .rect(framingRect(for: nil))
      route = try? await viewModel.calculateRoute(
        source: room.source.coordinate,
        destination: room.destination.coordinate
      )
      routeFailed = route == nil
      mapCamPos = .rect(framingRect(for: route))
    }
    .analyticsScreen(name: "Taxi Preview", class: String(describing: Self.self))
  }

  @ViewBuilder
  private var layout: some View {
    // A short screen — an iPhone in landscape, or iPhone Duo's outer display in landscape — is too
    // short to stack the map above the details, so they go side by side. The inner display and
    // iPad are tall enough in either orientation to stack them.
    if verticalSizeClass == .compact {
      sideBySideContent
    } else {
      stackedContent
        // Vertical edges only, so the map still runs to the top of the sheet but the controls
        // stay clear of a side bar — and of the front camera beside it on iPhone Duo's outer
        // display.
        .ignoresSafeArea(edges: .vertical)
    }
  }

  private var stackedContent: some View {
    VStack(spacing: 0) {
      // Room for the map to show above the details.
      Spacer(minLength: 160)

      details
    }
    .background {
      routeMap
        // Room above for the marker balloons, which rise above their coordinates.
        .safeAreaPadding(.top, 50)
        // Clear of the details and the fade above them, so neither end of the route nor the
        // Maps logo is dimmed.
        .safeAreaPadding(.bottom, detailsHeight + fadeHeight)
        // The map is backdrop, so it may run under a side bar; the controls
        // below may not.
        .ignoresSafeArea()
    }
  }

  /// The map on the left, filling the sheet to every edge — under the status bar too — and the
  /// details in a column on the right, whose controls stay clear of the notch, the home indicator
  /// and a side bar while its background runs under them.
  private var sideBySideContent: some View {
    // Scrolls only when the details are taller than the screen.
    ViewThatFits(in: .vertical) {
      detailsContent
      ScrollView {
        detailsContent
      }
      .scrollBounceBehavior(.basedOnSize)
      // Opens on Join rather than on the date.
      .defaultScrollAnchor(.bottom)
    }
    .padding(.top, 20)
    // At the bottom, as below the map in portrait, so Join stays where your thumb is.
    .frame(maxHeight: .infinity, alignment: .bottom)
    // Up under the navigation bar too: its only item, Close, sits over the map, and the bar's
    // height is most of what a landscape iPhone has to spare.
    .ignoresSafeArea(.container, edges: .top)
    .containerRelativeFrame(.horizontal) { width, _ in
      min(max(width * 0.45, 320), 400)
    }
    .background {
      sheetColor
        .ignoresSafeArea()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { detailsWidth = $0 }
    }
    .background(alignment: .leading) {
      LinearGradient(colors: [sheetColor.opacity(0), sheetColor], startPoint: .leading, endPoint: .trailing)
        .frame(width: fadeHeight)
        .offset(x: -fadeHeight)
        .ignoresSafeArea(edges: .vertical)
        .allowsHitTesting(false)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .background {
      routeMap
        // Room above for the Close button, and for the marker balloons, which rise above their
        // coordinates.
        .safeAreaPadding(.top, 70)
        // Clear of the details and the fade beside them.
        .safeAreaPadding(.trailing, detailsWidth + fadeHeight)
        // The map runs to the screen's rounded corner, which would clip the Maps logo and Legal
        // link in it.
        .safeAreaPadding(.leading, 20)
        .safeAreaPadding(.bottom, 12)
        .ignoresSafeArea()
    }
  }

  /// Kept short: the map frames the route above it, and every point taken here shrinks the route.
  private let fadeHeight: CGFloat = 64

  /// The details below the map, fading into it.
  private var details: some View {
    detailsContent
      .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { detailsHeight = $0 }
      // Both run under any side bar, as the map does, so it never shows past the panel's edges.
      .background {
        sheetColor
          .ignoresSafeArea(edges: .horizontal)
      }
      .background(alignment: .top) {
        LinearGradient(colors: [sheetColor.opacity(0), sheetColor], startPoint: .top, endPoint: .bottom)
          .frame(height: fadeHeight)
          .offset(y: -fadeHeight)
          .ignoresSafeArea(edges: .horizontal)
          .allowsHitTesting(false)
      }
  }

  private var detailsContent: some View {
    VStack(alignment: .leading, spacing: 16) {
      TaxiDepartureHeader(date: room.departAt)

      TaxiRouteStops(
        source: room.source.title.localized(),
        destination: room.destination.title.localized(),
        textStyle: .title3,
        weight: .semibold,
        markerSize: 14,
        rowSpacing: 8
      )

      // Held from the start, so the rows below don't move when the route arrives.
      if !routeFailed {
        TaxiRideStats(departAt: room.departAt, route: route)
      }

      TaxiRiderRow(participants: room.participants, capacity: room.capacity)

      actions
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 24)
  }

  /// Both ends of the ride and, once known, the route between them, with a small margin.
  /// `.automatic` pads far more generously, which leaves the route tiny in the strip of map
  /// visible above the details.
  private func framingRect(for route: MKRoute?) -> MKMapRect {
    let ends = [room.source.coordinate, room.destination.coordinate].map {
      MKMapRect(origin: MKMapPoint($0), size: MKMapSize(width: 0, height: 0))
    }
    var rect = ends[0].union(ends[1])
    if let route {
      rect = rect.union(route.polyline.boundingMapRect)
    }
    // At least about a kilometre across, so ends that coincide or sit side by side still show
    // the streets around them rather than zooming in as far as the map allows.
    let minimumSide = 1_000 * MKMapPointsPerMeterAtLatitude(room.source.coordinate.latitude)
    let margin = max(rect.width, rect.height) * 0.12
    rect = rect.insetBy(dx: -margin, dy: -margin)
    return rect.insetBy(
      dx: -max(minimumSide - rect.width, 0) / 2,
      dy: -max(minimumSide - rect.height, 0) / 2
    )
  }

  private var sheetColor: Color {
    colorScheme == .dark ? .black : .white
  }

  private var routeMap: some View {
    Map(position: $mapCamPos) {
      Marker(
        room.source.title.localized(),
        systemImage: "location.fill",
        coordinate: room.source.coordinate
      )
      .tint(.indigo)

      Marker(room.destination.title.localized(), coordinate: room.destination.coordinate)

      if let route {
        MapPolyline(route.polyline)
          .stroke(.indigo, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
      }
    }
    .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll))
    .disabled(true)
  }

  private var actions: some View {
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
            let joinedRoom = try await viewModel.joinRoom(id: room.id)
            dismiss()
            onJoin?(joinedRoom ?? room)
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

  private var isJoinButtonDisabled: Bool {
    room.participants.count >= room.capacity
    || viewModel.isJoined(participants: room.participants)
    || room.isDeparted
    || viewModel.blockStatus != .allow
  }
}

public extension View {
  /// Sizes a sheet presenting `TaxiPreviewView`: tall enough for the map above the details, or
  /// the whole screen on a short one, where a fixed height would run off the bottom and take the
  /// Join button with it.
  func taxiPreviewPresentation() -> some View {
    modifier(TaxiPreviewPresentation())
  }
}

private struct TaxiPreviewPresentation: ViewModifier {
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  func body(content: Content) -> some View {
    content
      .presentationDragIndicator(.visible)
      .presentationDetents(verticalSizeClass == .compact ? [.large] : [.height(560), .large])
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
      .taxiPreviewPresentation()
  }
}
