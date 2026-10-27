//
//  TaxiRideInfoView.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain

/// Everything about the ride in one place: when and where, your own arrival and luggage, who else
/// is riding, and the room's actions. Opened from the chat's title, in a popover on a wide
/// display and a sheet on a narrow one.
struct TaxiRideInfoView: View {
  let title: String
  let viewModel: TaxiChatViewModelProtocol
  /// Whether the view model's error is showing. Presented here, since the chat beneath cannot
  /// present it while this is open.
  @Binding var isErrorPresented: Bool
  let onLeave: () -> Void

  @Environment(\.openURL) private var openURL

  @State private var showCallTaxiAlert: Bool = false
  @State private var showReportSheet: Bool = false
  @State private var reportSheetDetent: PresentationDetent = .height(450)
  @State private var showLeaveConfirmation: Bool = false
  /// Set when the departure time passes while this is open, so the arrival tile is disabled then
  /// rather than at the next unrelated redraw.
  @State private var hasPassedDeparture: Bool = false

  private var canMarkArrival: Bool {
    viewModel.isArrivalToggleEnabled && !hasPassedDeparture
  }

  private var room: TaxiRoom { viewModel.room }

  var body: some View {
    List {
      Section {
        header
        actions
      }
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))

      Section {
        HStack(spacing: 10) {
          statusTile(
            isOn: viewModel.isArrived,
            tint: .green,
            on: (Text("Arrived", bundle: .module), "checkmark.circle.fill"),
            off: (Text("I'm Here", bundle: .module), "figure.wave")
          ) {
            viewModel.updateArrival(isArrived: !viewModel.isArrived)
          }
          .disabled(!canMarkArrival)

          statusTile(
            isOn: viewModel.hasCarrier,
            tint: .indigo,
            on: (Text("With Luggage", bundle: .module), "suitcase.rolling.fill"),
            off: (Text("No Luggage", bundle: .module), "suitcase.rolling")
          ) {
            viewModel.updateCarrier(hasCarrier: !viewModel.hasCarrier)
          }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
      } header: {
        Text("My Status", bundle: .module)
      } footer: {
        if !canMarkArrival {
          Text("You can mark your arrival only before the ride departs.", bundle: .module)
        }
      }

      ridersSection

      Section {
        // Confirmed first: a stray tap at the foot of the list would otherwise give up your seat.
        Button(role: .destructive) {
          showLeaveConfirmation = true
        } label: {
          Label(String(localized: "Leave", bundle: .module), systemImage: "rectangle.portrait.and.arrow.right")
            .foregroundStyle(.red)
        }
        .disabled(!viewModel.isLeaveRoomAvailable)
        .confirmationDialog(
          String(localized: "Leave this room?", bundle: .module),
          isPresented: $showLeaveConfirmation,
          titleVisibility: .visible
        ) {
          Button(String(localized: "Leave", bundle: .module), role: .destructive, action: onLeave)
          Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
        } message: {
          Text("You'll give up your seat in this ride.", bundle: .module)
        }
      }
    }
    .task(id: room.departAt) {
      let wait = room.departAt.timeIntervalSinceNow
      guard wait > 0 else { return }
      do {
        try await Task.sleep(for: .seconds(wait))
        hasPassedDeparture = true
      } catch {
        // Closed before departure.
      }
    }
    .animation(.snappy, value: viewModel.isArrived)
    .animation(.snappy, value: viewModel.hasCarrier)
    .navigationTitle(Text("Ride Info", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .alert(
      String(localized: "Call Taxi", bundle: .module),
      isPresented: $showCallTaxiAlert,
      actions: {
        Button(String(localized: "Open Kakao T", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.kakaoTURL(source: room.source, destination: room.destination) {
            openURL(url)
          }
        }
        Button(String(localized: "Open Uber", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.uberURL(source: room.source, destination: room.destination) {
            openURL(url)
          }
        }
        Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
      },
      message: {
        Text(
          String(localized: "You can launch the taxi app with the departure and destination already set. Once everyone has gathered at the departure point, press the button to call a taxi from \(room.source.title.localized()) to \(room.destination.title.localized()).", bundle: .module)
        )
      }
    )
    .alert(
      viewModel.alertState?.title ?? String(localized: "Error", bundle: .module),
      isPresented: $isErrorPresented,
      actions: {
        Button(String(localized: "Okay", bundle: .module), role: .close) { }
      },
      message: {
        Text(viewModel.alertState?.message ?? "")
      }
    )
    .sheet(isPresented: $showReportSheet) {
      TaxiReportView(room: room)
        .presentationDragIndicator(.visible)
        // `.large` as well for when the participant list outgrows 450
        // points; the selection keeps 450 as the opening height.
        .presentationDetents([.height(450), .large], selection: $reportSheetDetent)
    }
  }

  private var header: some View {
    VStack(spacing: 6) {
      TaxiRiderCluster(riders: viewModel.riders, size: 96)
        .padding(.bottom, 6)

      Text(title)
        .font(.title2.weight(.bold))
        .multilineTextAlignment(.center)

      Text("\(room.source.title.localized()) → \(room.destination.title.localized())", bundle: .module)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      TaxiDepartureChips(date: room.departAt)
        .padding(.top, 10)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 8)
  }

  private var actions: some View {
    HStack(spacing: 10) {
      ShareLink(
        // The production or development service's invite link, whichever this build talks to.
        item: Constants.taxiInviteURL.appending(path: room.id),
        message: Text("🚕 Looking for someone to ride with on \(room.departAt.formattedString) from \(room.source.title) to \(room.destination.title)! 🚕", bundle: .module)
      ) {
        actionLabel(Text("Share", bundle: .module), systemImage: "square.and.arrow.up")
      }

      Button {
        showCallTaxiAlert = true
      } label: {
        actionLabel(Text("Call Taxi", bundle: .module), systemImage: "car.fill")
      }

      Button {
        reportSheetDetent = .height(450)
        showReportSheet = true
      } label: {
        actionLabel(Text("Report", bundle: .module), systemImage: "exclamationmark.triangle.fill")
      }
      .disabled(room.participants.count <= 1)
    }
    .buttonStyle(.borderless)
  }

  private func actionLabel(_ title: Text, systemImage: String) -> some View {
    VStack(spacing: 6) {
      Image(systemName: systemImage)
        .font(.title3)
        .frame(height: 24)
      title
        .font(.caption.weight(.medium))
    }
    .frame(maxWidth: .infinity, minHeight: 64)
    .background(Color.secondarySystemGroupedBackground, in: .rect(cornerRadius: 16))
  }

  private func statusTile(
    isOn: Bool,
    tint: Color,
    on: (Text, String),
    off: (Text, String),
    action: @escaping () -> Void
  ) -> some View {
    let (title, symbol) = isOn ? on : off
    return Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: symbol)
          .font(.title2)
          .frame(height: 28)
          .contentTransition(.symbolEffect(.replace))
        title
          .font(.footnote.weight(.semibold))
      }
      .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
      .frame(maxWidth: .infinity, minHeight: 80)
      .background(isOn ? AnyShapeStyle(tint) : AnyShapeStyle(Color.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
    .buttonStyle(.borderless)
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }

  /// You first, then whoever has arrived, then whoever is on the way.
  private var sortedRiders: [TaxiParticipant] {
    let me = viewModel.taxiUser?.oid
    return viewModel.riders.enumerated().sorted { a, b in
      let rank = { (r: TaxiParticipant) in r.id == me ? 0 : r.isArrived ? 1 : 2 }
      return (rank(a.element), a.offset) < (rank(b.element), b.offset)
    }
    .map(\.element)
  }

  /// Who is already at the departure point, then who is still on the way, so a glance shows who
  /// the ride is waiting for.
  @ViewBuilder
  private var ridersSection: some View {
    let arrived = sortedRiders.filter(\.isArrived)
    let onTheWay = sortedRiders.filter { !$0.isArrived }

    if !arrived.isEmpty {
      Section {
        ForEach(arrived) { riderRow($0) }
      } header: {
        Label {
          Text("Arrived \(arrived.count)", bundle: .module)
        } icon: {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }

    if !onTheWay.isEmpty {
      Section {
        ForEach(onTheWay) { riderRow($0) }
      } header: {
        Label {
          Text("On the Way \(onTheWay.count)", bundle: .module)
        } icon: {
          Image(systemName: "figure.walk")
        }
      }
    }
  }

  private func riderRow(_ rider: TaxiParticipant) -> some View {
    HStack(spacing: 12) {
      TaxiRiderAvatar(participant: rider, size: 36, showsLuggage: false)
      nameLine(rider)
      Spacer(minLength: 0)
      if rider.hasCarrier {
        Label(String(localized: "With Luggage", bundle: .module), systemImage: "suitcase.rolling.fill")
          .labelStyle(.iconOnly)
          .foregroundStyle(.indigo)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private func nameLine(_ rider: TaxiParticipant) -> some View {
    HStack(spacing: 4) {
      Text(rider.nickname)
        .font(.body.weight(.semibold))
      if rider.badge {
        Image(systemName: "phone.circle.fill")
          .font(.subheadline)
          .foregroundStyle(Color.accentColor)
          .accessibilityLabel(Text("Phone Verified", bundle: .module))
      }
      if rider.id == viewModel.taxiUser?.oid {
        Text("Me", bundle: .module)
          .font(.caption2.weight(.bold))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.fill.tertiary, in: .capsule)
      }
    }
  }
}

extension TaxiChatViewModelProtocol {
  /// The room's riders, with your own arrival and luggage as you last set them rather than as the
  /// room last came back from the server.
  var riders: [TaxiParticipant] {
    room.participants.map { rider in
      guard rider.id == taxiUser?.oid else { return rider }
      return TaxiParticipant(
        id: rider.id,
        name: rider.name,
        nickname: rider.nickname,
        profileImageURL: rider.profileImageURL,
        withdraw: rider.withdraw,
        badge: rider.badge,
        isSettlement: rider.isSettlement,
        isArrived: isArrived,
        hasCarrier: hasCarrier,
        readAt: rider.readAt
      )
    }
  }
}
