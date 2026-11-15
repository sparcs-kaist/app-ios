//
//  PlaceDetailView.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import MapKit
import BuddyDomain

struct PlaceDetailView: View {
  let place: CampusPlace
  let viewModel: CampusMapViewModelProtocol
  var showsHeader: Bool = true
  var onSelectPlace: ((CampusPlace) -> Void)?
  var onClose: (() -> Void)?

  @State private var showsAllHours = false

  private var reviews: [PlaceReview] {
    viewModel.reviews(for: place)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      if showsHeader {
        PlaceDetailHeader(place: place, onClose: onClose)
      }

      actions

      if place.category == .olevStop {
        olevSection
      } else {
        glanceStrip
      }
      if let menu = viewModel.cafeteriaMenu(for: place) {
        PlaceCardSection(title: String(localized: "Today's Menu", bundle: .module)) {
          CafeteriaMenuView(menu: menu)
        }
      }
      if let menu = viewModel.restaurantMenu(for: place) {
        PlaceCardSection(title: String(localized: "Menu", bundle: .module)) {
          RestaurantMenuView(menu: menu)
        }
      }

      if let summary = place.summary {
        PlaceCardSection(title: String(localized: "About", bundle: .module)) {
          Text(summary)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      facilities
      details

      PlaceReviewsSection(
        reviews: reviews,
        placeName: place.displayName,
        category: place.category,
        onUpvote: { review in viewModel.toggleUpvote(review) },
        onWrite: { rating, text, photos in
          viewModel.writeReview(for: place, rating: rating, text: text, photos: photos)
        }
      )

      Button {
      } label: {
        Label(String(localized: "Report an Issue", bundle: .module), systemImage: "exclamationmark.bubble")
          .font(.subheadline.weight(.medium))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
      }
      .buttonStyle(.bordered)
      .buttonBorderShape(.roundedRectangle(radius: 14))
      .tint(.secondary)
    }
  }

  // MARK: - Actions

  private var actions: some View {
    let distance = viewModel.distance(to: place)

    return HStack(spacing: 8) {
      Button(action: openDirections) {
        HStack(spacing: 10) {
          Image(systemName: "figure.walk")
            .font(.title2)
          VStack(alignment: .leading, spacing: 2) {
            Text("Directions", bundle: .module)
              .font(.headline)
              .lineLimit(1)
              .minimumScaleFactor(0.85)
            Text("\(distance.distanceText) · \(distance.walkingMinutes) min", bundle: .module)
              .font(.caption.weight(.medium))
              .foregroundStyle(.white.opacity(0.85))
              .lineLimit(1)
              .minimumScaleFactor(0.85)
          }
          Spacer(minLength: 4)
          Image(systemName: "arrow.up.right")
            .font(.title3.weight(.semibold))
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 14)
      }
      .buttonStyle(PlaceActionButtonStyle(isProminent: true))

      if let phoneNumber = place.phoneNumber,
         let url = URL(string: "tel:\(phoneNumber.filter(\.isNumber))") {
        Link(destination: url) {
          actionLabel(title: String(localized: "Call", bundle: .module), systemImage: "phone.fill")
        }
        .buttonStyle(PlaceActionButtonStyle())
      }

      ShareLink(item: place.shareText) {
        actionLabel(title: String(localized: "Share", bundle: .module), systemImage: "square.and.arrow.up")
      }
      .buttonStyle(PlaceActionButtonStyle())
    }
  }

  private func actionLabel(title: String, systemImage: String) -> some View {
    VStack(spacing: 2) {
      Image(systemName: systemImage)
        .font(.title3)
      Text(title)
        .font(.caption.weight(.semibold))
    }
    .frame(minWidth: 48, minHeight: 44)
    .padding(.horizontal, 6)
  }

  private func openDirections() {
    let item = MKMapItem(location: CLLocation(latitude: place.latitude, longitude: place.longitude), address: nil)
    item.name = place.displayName
    item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
  }

  private var glanceStrip: some View {
    Group(subviews: glanceItems) { items in
      if !items.isEmpty {
        HStack(spacing: 0) {
          ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            if index > 0 {
              Rectangle().fill(.separator).frame(width: 1)
            }
            item
          }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
      }
    }
  }

  @ViewBuilder
  private var glanceItems: some View {
    if let status = place.openingHours?.status(at: .now) {
      glanceItem(title: String(localized: "Hours", bundle: .module)) {
        Text(status.title).foregroundStyle(status.tint)
      }
    }

    if let rating = PlaceRatingSummary(reviews: reviews) {
      glanceItem(title: String(localized: "\(rating.count) Ratings", bundle: .module)) {
        HStack(spacing: 3) {
          Text(rating.average, format: .number.precision(.fractionLength(1)))
          Image(systemName: "star.fill")
            .font(.caption)
            .foregroundStyle(.orange)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(rating.average, format: .number.precision(.fractionLength(1))) out of 5 stars", bundle: .module))
      }
    }

    if let menu = viewModel.cafeteriaMenu(for: place), let prices = menu.meals.flatMap(\.courses).map(\.price).min() {
      glanceItem(title: String(localized: "From", bundle: .module)) {
        Text(prices.wonText)
      }
    } else if let menu = viewModel.restaurantMenu(for: place), let price = menu.sections.flatMap(\.items).map(\.price).min() {
      glanceItem(title: String(localized: "From", bundle: .module)) {
        Text(price.wonText)
      }
    } else if let code = place.code {
      glanceItem(title: String(localized: "Code", bundle: .module)) {
        Text(code)
      }
    }
  }

  private func glanceItem<Value: View>(title: String, @ViewBuilder value: () -> Value) -> some View {
    VStack(spacing: 2) {
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
      value()
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 6)
    .accessibilityElement(children: .combine)
  }

  // MARK: - Sections

  @ViewBuilder
  private var olevSection: some View {
    OLEVArrivalsView(stop: place, timetable: viewModel.olevTimetable)

    PlaceCardSection(
      title: String(localized: "Stops", bundle: .module),
      trailing: AnyView(
        Text("\(viewModel.olevStops.count) stops", bundle: .module)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      )
    ) {
      OLEVRouteList(
        stops: viewModel.olevStops,
        timetable: viewModel.olevTimetable,
        currentStopID: place.id,
        onSelect: onSelectPlace
      )
      .padding(.vertical, -8)
    }
  }

  @ViewBuilder
  private var facilities: some View {
    let inside = viewModel.facilities(in: place)
    if !inside.isEmpty {
      PlaceCardSection(title: String(localized: "Inside", bundle: .module)) {
        VStack(spacing: 10) {
          ForEach(inside) { facility in
            Button {
              onSelectPlace?(facility)
            } label: {
              PlaceRow(place: facility, viewModel: viewModel)
            }
            .buttonStyle(.plain)
            .disabled(onSelectPlace == nil)
            if facility.id != inside.last?.id {
              Divider().padding(.leading, 52)
            }
          }
        }
      }
    }
  }

  private var hasDetails: Bool {
    place.openingHours != nil || place.hoursNote != nil || viewModel.building(of: place) != nil
      || place.phoneNumber != nil
  }

  @ViewBuilder
  private var details: some View {
    if hasDetails {
      detailRows
    }
  }

  private var detailRows: some View {
    PlaceCardSection(title: String(localized: "Details", bundle: .module)) {
      DividedRows {
        if let hours = place.openingHours {
          detailRow(title: String(localized: "Hours", bundle: .module)) {
            Button {
              withAnimation(.snappy) { showsAllHours.toggle() }
            } label: {
              HStack {
                OpeningStatusText(status: hours.status(at: .now))
                Spacer()
                Image(systemName: "chevron.down")
                  .rotationEffect(.degrees(showsAllHours ? 180 : 0))
                  .foregroundStyle(.secondary)
              }
              .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if showsAllHours {
              WeeklyHoursView(hours: hours)
                .padding(.top, 4)
            }
            if let note = place.hoursNote {
              Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        } else if let note = place.hoursNote {
          detailRow(title: String(localized: "Hours", bundle: .module)) {
            Text(note)
          }
        }

        if let building = viewModel.building(of: place) {
          detailRow(title: String(localized: "Located In", bundle: .module)) {
            Button {
              onSelectPlace?(building)
            } label: {
              Text("\(building.displayName) (\(building.code ?? ""))", bundle: .module)
            }
            .disabled(onSelectPlace == nil)
          }
        }

        if let phoneNumber = place.phoneNumber {
          detailRow(title: String(localized: "Phone", bundle: .module)) {
            Text(phoneNumber)
              .foregroundStyle(.tint)
          }
        }
      }
    }
  }

  private func detailRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.footnote)
        .foregroundStyle(.secondary)
      content()
        .font(.subheadline)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Name, category line and the round close/share buttons at the top of a place card.
struct PlaceDetailHeader: View {
  let place: CampusPlace
  var onClose: (() -> Void)?

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(place.displayName)
          .font(.title.weight(.bold))
          .lineLimit(2)
          .minimumScaleFactor(0.75)
        PlaceSubtitle(subtitle: place.subtitle, floor: place.displayFloor)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
      if let onClose {
        CloseButton(action: onClose)
      }
    }
  }
}

/// The round grey ✕ Apple Maps puts in a place card's corner. It is filled rather than glass: it
/// sits on the sheet, which is glass already.
struct CloseButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "xmark")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.secondary)
        .frame(width: 34, height: 34)
        .background(.fill.tertiary, in: .circle)
        .contentShape(.circle)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text("Close", bundle: .module))
  }
}

/// A place card's action tiles: one filled blue for the way there, the rest grey with blue glyphs.
private struct PlaceActionButtonStyle: ButtonStyle {
  var isProminent = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(isProminent ? AnyShapeStyle(.white) : AnyShapeStyle(Color.blue))
      .padding(.vertical, 6)
      .background(
        isProminent ? AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(.fill.tertiary),
        in: .rect(cornerRadius: 16, style: .continuous)
      )
      .opacity(configuration.isPressed ? 0.6 : 1)
      .animation(.snappy(duration: 0.15), value: configuration.isPressed)
  }
}

/// Stacks its rows with a divider between each pair, however many of them are present.
private struct DividedRows<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Group(subviews: content) { subviews in
        ForEach(subviews) { subview in
          subview
          if subview.id != subviews.last?.id {
            Divider()
          }
        }
      }
    }
  }
}

/// Every day of the week, today in bold.
struct WeeklyHoursView: View {
  let hours: OpeningHours

  var body: some View {
    let calendar = Calendar.current
    let today = calendar.component(.weekday, from: .now)
    // Start the week where the user's calendar does.
    let days = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }

    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
      ForEach(days, id: \.self) { day in
        GridRow {
          Text(calendar.weekdaySymbols[day - 1])
          let intervals = hours.intervals(on: day)
          Text(
            intervals.isEmpty
              ? String(localized: "Closed", bundle: .module)
              : intervals == [.allDay]
                ? String(localized: "Open 24 hours", bundle: .module)
                : intervals.map { "\($0.opens.minutesAsTimeText) – \($0.closes.minutesAsTimeText)" }.joined(separator: ", ")
          )
          .foregroundStyle(intervals.isEmpty ? .secondary : .primary)
        }
        .fontWeight(day == today ? .semibold : .regular)
      }
    }
    .font(.subheadline)
  }
}
