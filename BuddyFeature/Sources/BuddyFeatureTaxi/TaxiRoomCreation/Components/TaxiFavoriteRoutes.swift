//
//  TaxiFavoriteRoutes.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain
import Haptica

/// Your favourite routes, one tap from filling the picker above. While the picker holds a route
/// you haven't saved, a chip to save it leads the row; long-pressing a route removes it. Shows
/// nothing until there is a route to offer or one to save.
struct TaxiFavoriteRoutes: View {
  @Binding var source: TaxiLocation?
  @Binding var destination: TaxiLocation?
  let locations: [TaxiLocation]
  /// The colour of a chip that isn't the route chosen, to stand apart from what is behind it.
  var chipBackground: Color = .secondarySystemGroupedBackground

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private var favorites: TaxiFavorites { .shared }

  private struct ResolvedRoute: Identifiable {
    let route: TaxiFavoritesStore.Route
    let source: TaxiLocation
    let destination: TaxiLocation
    var id: TaxiFavoritesStore.Route { route }
  }

  /// Saved routes whose places still exist.
  private var routes: [ResolvedRoute] {
    let byID = Dictionary(locations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    return favorites.routes.compactMap { route in
      guard let source = byID[route.sourceID], let destination = byID[route.destinationID] else { return nil }
      return ResolvedRoute(route: route, source: source, destination: destination)
    }
  }

  /// The picker's route, when both ends are chosen and it isn't saved yet.
  private var unsavedRoute: (TaxiLocation, TaxiLocation)? {
    guard let source, let destination, !favorites.contains(source: source, destination: destination) else {
      return nil
    }
    return (source, destination)
  }

  var body: some View {
    let routes = routes

    if unsavedRoute != nil || !routes.isEmpty {
      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          if let (source, destination) = unsavedRoute {
            Button {
              Haptic.selection.generate()
              withAnimation(.snappy) {
                favorites.saveRoute(source: source, destination: destination)
              }
            } label: {
              Label(String(localized: "Save Route", bundle: .module), systemImage: "star")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.12), in: .capsule)
            }
            .buttonStyle(.plain)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
          }

          ForEach(routes) { route in
            chip(route)
          }
        }
        .padding(.horizontal)
        .animation(.snappy, value: favorites.routes)
      }
      .scrollIndicators(.hidden)
      .modifier(EdgeTreatment(fadesTrailingEdge: horizontalSizeClass == .regular))
    }
  }

  private func chip(_ route: ResolvedRoute) -> some View {
    let isChosen = route.source == source && route.destination == destination

    return Button {
      Haptic.selection.generate()
      withAnimation(.snappy) {
        source = route.source
        destination = route.destination
      }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "star.fill")
          .font(.caption2)
          .foregroundStyle(.yellow)
        Text(route.source.title.localized())
        Image(systemName: "arrow.right")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.tertiary)
          .accessibilityHidden(true)
        Text(route.destination.title.localized())
      }
      .font(.subheadline.weight(.medium))
      .foregroundStyle(isChosen ? Color.accentColor : .primary)
      .lineLimit(1)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(isChosen ? Color.accentColor.opacity(0.12) : chipBackground, in: .capsule)
      .contentShape(.capsule)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isChosen ? .isSelected : [])
    .contextMenu {
      Button(String(localized: "Remove from Favourites", bundle: .module), systemImage: "star.slash", role: .destructive) {
        withAnimation(.snappy) {
          favorites.removeRoute(route.route)
        }
      }
    }
  }

  /// On an iPhone in portrait the row runs to the edge of the screen, and the chips scroll on off
  /// it. Where it ends short of the edge — in a column of a wide layout, or beside iPhone Duo's
  /// vertical bar — the chips fade out there instead of being cut off along a line, or running
  /// on under the bar's buttons. The fade is as wide as the row's padding, so a row at rest
  /// shows every chip whole.
  private struct EdgeTreatment: ViewModifier {
    let fadesTrailingEdge: Bool

    func body(content: Content) -> some View {
      if #available(iOS 27.1, *) {
        content.modifier(BesideVerticalBar(isWide: fadesTrailingEdge))
      } else {
        Self.apply(to: content, fades: fadesTrailingEdge)
      }
    }

    @ViewBuilder
    static func apply<V: View>(to content: V, fades: Bool) -> some View {
      if fades {
        content.mask {
          HStack(spacing: 0) {
            Rectangle()
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
              .frame(width: 16)
          }
        }
      } else {
        content.scrollClipDisabled()
      }
    }
  }

  @available(iOS 27.1, *)
  private struct BesideVerticalBar: ViewModifier {
    let isWide: Bool
    @Environment(\.toolbarVerticalEdge) private var verticalBarEdge

    func body(content: Content) -> some View {
      EdgeTreatment.apply(to: content, fades: isWide || verticalBarEdge != nil)
    }
  }
}
