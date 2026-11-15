//
//  CampusExploreView.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import MapKit
import BuddyDomain

/// The Map tab: the campus map fills the screen, with the system's own pieces around it — the
/// navigation bar's search button, category chips under it, a row of place cards along the bottom
/// and a sheet for the place in focus.
struct CampusExploreView: View {
  let viewModel: CampusMapViewModelProtocol

  @State private var searchText = ""
  /// Search is this screen's own: a toolbar button that opens a field over the map. The system's
  /// minimised `searchable` looks the same but never reports being closed — its `isPresented`
  /// binding, its focus and the environment's `isSearching` all stay true — so the results could
  /// not be taken off the map again.
  @State private var isSearching = false
  @FocusState private var isSearchFocused: Bool
  @State private var filter: CampusPlaceFilter?
  @State private var selectedPlace: CampusPlace?
  @State private var selectedPlaceDetent: PresentationDetent = .fraction(CampusExploreView.cardFraction)
  @State private var hasScrolledPlaceDetails = false
  @State private var position: MapCameraPosition = .kaist
  @State private var mapStyle: CampusMapStyle = .standard

  @Namespace private var mapScope

  /// How much of the screen a place's sheet takes while the map stays usable behind it.
  private static let cardFraction: CGFloat = 0.42
  /// Roughly what a leading sheet covers on a wide screen.
  private static let leadingSheetWidth: CGFloat = 380

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    GeometryReader { proxy in
      CampusMapContent(
        viewModel: viewModel,
        places: mapPlaces,
        position: $position,
        selection: selection,
        showsOLEVRoute: filter == .olev || selectedPlace?.category == .olevStop,
        style: mapStyle,
        scope: mapScope
      )
      // Tells the map what the sheet covers, so a focused place lands in the part still showing:
      // the leading side on a wide screen, the bottom otherwise. The bars, the chips and the
      // cards it learns from the safe area.
      .safeAreaPadding(sheetInsets(in: proxy))
      .overlay(alignment: .topTrailing) {
        mapControls
      }
      .safeAreaInset(edge: .top, spacing: 0) {
        PlaceFilterChips(selection: $filter)
          .background {
            GeometryReader { filterProxy in
              Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: proxy.safeAreaInsets.top + filterProxy.size.height + 48)
                .mask {
                  VStack(spacing: 0) {
                    Color.black.frame(height: proxy.safeAreaInsets.top)
                    LinearGradient(
                      colors: [.black, .clear],
                      startPoint: .top,
                      endPoint: .bottom
                    )
                  }
                }
                .offset(y: -proxy.safeAreaInsets.top)
            }
            .allowsHitTesting(false)
          }
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if selectedPlace == nil {
          carousel
        }
      }
    }
    // The map screen holds still under the keyboard; only search's own content makes room for it.
    .ignoresSafeArea(.keyboard)
    // Search is an overlay on the whole screen, which stays as it is underneath.
    .overlay {
      if isSearching {
        searchResults
      }
    }
    .navigationTitle(Text("Campus", bundle: .module))
    .toolbarTitleDisplayMode(.inlineLarge)
    .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
    .toolbar {
      ToolbarItemGroup {
        Button(
          String(localized: "Map Style", bundle: .module),
          systemImage: mapStyle == .standard ? "map" : "globe.asia.australia.fill",
          action: toggleMapStyle
        )
        Button(String(localized: "My Location", bundle: .module), systemImage: "location.fill", action: showMyLocation)
      }

      // Search keeps a capsule of its own, always the trailing one.
      ToolbarSpacer(.fixed)

      ToolbarItem {
        Button(String(localized: "Search", bundle: .module), systemImage: "magnifyingglass") {
          withAnimation(.snappy) { isSearching = true }
        }
      }
    }
    // The search field takes the bar's place while it is open.
    .toolbar(isSearching ? .hidden : .visible, for: .navigationBar)
    .mapScope(mapScope)
    .onChange(of: filter) { _, filter in
      withAnimation {
        position = filter.map { .fitting(places(in: $0)) } ?? .kaist
      }
    }
    .onChange(of: selectedPlace?.id) { _, _ in
      hasScrolledPlaceDetails = false
    }
    .sheet(
      isPresented: Binding(get: { selectedPlace != nil }, set: { if !$0 { selectedPlace = nil } }),
      onDismiss: {
        selectedPlaceDetent = .fraction(Self.cardFraction)
        hasScrolledPlaceDetails = false
      }
    ) {
      if let place = selectedPlace {
        NavigationStack {
          GeometryReader { sheetProxy in
            ScrollView {
              PlaceDetailView(place: place, viewModel: viewModel, showsHeader: false, onSelectPlace: { show($0) })
                .padding(.horizontal)
                .padding(.bottom, sheetProxy.safeAreaInsets.bottom + 16)
            }
            .scrollEdgeEffectStyle(.hard, for: .top)
            .scrollEdgeEffectHidden(selectedPlaceDetent != .large || !hasScrolledPlaceDetails, for: .top)
            .onScrollGeometryChange(for: Bool.self) { geometry in
              geometry.contentOffset.y + geometry.contentInsets.top > 1
            } action: { _, isScrolled in
              hasScrolledPlaceDetails = isScrolled
            }
            .safeAreaBar(edge: .top, spacing: 0) {
              sheetHeader(for: place)
            }
            .animation(.easeInOut(duration: 0.25), value: selectedPlaceDetent == .large && hasScrolledPlaceDetails)
            .ignoresSafeArea(.container, edges: .bottom)
            .id(place.id)
          }
          .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.fraction(Self.cardFraction), .large], selection: $selectedPlaceDetent)
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(Self.cardFraction)))
        .presentationDragIndicator(.visible)
        // On a wide screen the sheet stands on the leading side, beside the map, not across it.
        .leadingPresentationPlacement()
      }
    }
  }

  private func sheetHeader(for place: CampusPlace) -> some View {
    HStack(spacing: 12) {
      PlaceSheetTitle(title: place.displayName, subtitle: place.subtitle, floor: place.displayFloor)
        .padding(.leading, 8)
        .padding(.top, 8)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .id(place.id)

      GlassEffectContainer(spacing: 8) {
        HStack(spacing: 8) {
          Button {
            withAnimation(.snappy) { viewModel.togglePin(place) }
          } label: {
            Image(systemName: viewModel.isPinned(place) ? "pin.fill" : "pin")
              .font(.system(size: 17, weight: .medium))
              .foregroundStyle(viewModel.isPinned(place) ? Color.accentColor : Color.primary)
              .frame(width: 44, height: 44)
              .glassEffect(.regular.interactive(), in: .circle)
          }
          .accessibilityLabel(
            viewModel.isPinned(place)
              ? String(localized: "Unpin", bundle: .module)
              : String(localized: "Pin", bundle: .module)
          )
          .sensoryFeedback(.selection, trigger: viewModel.isPinned(place))

          Button(role: .close) {
            selectedPlace = nil
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.primary)
              .frame(width: 44, height: 44)
              .glassEffect(.regular.interactive(), in: .circle)
          }
          .accessibilityLabel(Text("Close", bundle: .module))
        }
        .buttonStyle(.plain)
        .fixedSize()
      }
    }
    .padding(.horizontal)
    .padding(.top, 12)
    .padding(.bottom, 12)
  }

  // MARK: - State

  /// The map's marker selection and the sheet's place are one thing.
  private var selection: Binding<String?> {
    Binding {
      selectedPlace?.id
    } set: { id in
      if let id, let place = viewModel.place(id: id) {
        show(place)
      } else {
        selectedPlace = nil
      }
    }
  }

  /// Markers follow the chips: a category's places, or the campus landmarks.
  private var mapPlaces: [CampusPlace] {
    var places = filter.map(places(in:)) ?? viewModel.landmarks
    if let selectedPlace, !places.contains(selectedPlace) {
      places.append(selectedPlace)
    }
    return places
  }

  /// The cards along the bottom: the chosen category nearest first, otherwise the pinned places.
  private var carouselPlaces: [CampusPlace] {
    if let filter { return places(in: filter) }
    return viewModel.pinnedPlaces.isEmpty ? viewModel.nearby(limit: 6) : viewModel.pinnedPlaces
  }

  private func sheetInsets(in proxy: GeometryProxy) -> EdgeInsets {
    guard selectedPlace != nil else { return EdgeInsets() }
    if horizontalSizeClass == .regular {
      return EdgeInsets(top: 0, leading: Self.leadingSheetWidth, bottom: 0, trailing: 0)
    }
    let covered = proxy.size.height * Self.cardFraction - proxy.safeAreaInsets.bottom
    return EdgeInsets(top: 0, leading: 0, bottom: max(covered, 0), trailing: 0)
  }

  private func places(in filter: CampusPlaceFilter) -> [CampusPlace] {
    // Nearby is the handful around you, not the whole campus sorted by distance.
    viewModel.nearby(filter.categories, limit: filter == .nearby ? 12 : .max)
  }

  private func show(_ place: CampusPlace) {
    guard place != selectedPlace else { return }
    closeSearch()
    withAnimation {
      selectedPlace = place
      position = .focused(on: place)
    }
  }

  // MARK: - Pieces

  /// The compass, shown once the map is turned. Map style and my-location are in the toolbar.
  private var mapControls: some View {
    MapCompass(scope: mapScope)
      .padding(.top, 10)
      .padding(.trailing, 12)
  }

  private var carousel: some View {
    ScrollView(.horizontal) {
      GlassEffectContainer(spacing: 10) {
        HStack(spacing: 10) {
          ForEach(carouselPlaces) { place in
            Button {
              show(place)
            } label: {
              PlaceCarouselCard(place: place, viewModel: viewModel)
            }
            .buttonStyle(.plain)
            .contextMenu {
              Button(
                viewModel.isPinned(place) ? String(localized: "Unpin", bundle: .module) : String(localized: "Pin", bundle: .module),
                systemImage: viewModel.isPinned(place) ? "pin.slash" : "pin"
              ) {
                withAnimation { viewModel.togglePin(place) }
              }
            }
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .scrollTargetLayout()
      }
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
  }

  private func toggleMapStyle() {
    withAnimation { mapStyle = mapStyle == .standard ? .satellite : .standard }
  }

  private func showMyLocation() {
    withAnimation {
      position = .camera(MapCamera(centerCoordinate: viewModel.currentLocation.coordinate, distance: 900))
    }
  }

  private func closeSearch() {
    isSearchFocused = false
    withAnimation(.snappy) {
      isSearching = false
      searchText = ""
    }
  }

  /// The open search: a field and a close button where the navigation bar was, results below.
  private var searchResults: some View {
    VStack(spacing: 0) {
      GlassEffectContainer(spacing: 10) {
        HStack(spacing: 10) {
          HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .font(.body.weight(.medium))
              .foregroundStyle(.secondary)

            TextField(text: $searchText, prompt: Text("Search KAIST", bundle: .module)) {
              Text("Search", bundle: .module)
            }
            .focused($isSearchFocused)
            .submitLabel(.search)
            .autocorrectionDisabled()

            if !searchText.isEmpty {
              Button {
                searchText = ""
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .foregroundStyle(.secondary)
              }
              .buttonStyle(.plain)
              .accessibilityLabel(Text("Clear", bundle: .module))
            }
          }
          .padding(.horizontal, 14)
          .frame(height: 48)
          .glassEffect(.regular.interactive(), in: .capsule)

          Button(action: closeSearch) {
            Image(systemName: "xmark")
              .font(.system(size: 17, weight: .medium))
              .frame(width: 48, height: 48)
              .contentShape(.circle)
          }
          .buttonStyle(.plain)
          .glassEffect(.regular.interactive(), in: .circle)
          .accessibilityLabel(Text("Close", bundle: .module))
        }
      }
      .padding(.horizontal)
      .padding(.top, 6)
      .padding(.bottom, 8)

      searchResultsList
    }
    // Edge to edge and behind the keyboard, so the keyboard slides over it instead of lifting it.
    .background {
      Rectangle()
        .fill(.regularMaterial)
        .ignoresSafeArea()
    }
    .onAppear { isSearchFocused = true }
    .transition(.opacity)
  }

  private var searchResultsList: some View {
    ScrollView {
      Group {
        if !searchText.isEmpty {
          PlaceSearchResults(viewModel: viewModel, query: searchText) { show($0) }
        } else if !viewModel.pinnedPlaces.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            MapSectionHeader(title: String(localized: "Pinned", bundle: .module))
            PlaceListCard(places: viewModel.pinnedPlaces, viewModel: viewModel) { show($0) }
          }
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 12)
      .contentWidth()
    }
    .scrollDismissesKeyboard(.immediately)
  }
}

private extension View {
  /// Places a sheet on the leading side where the screen is wide enough; before iOS 27 there is
  /// no such placement and the sheet stays where the system puts it.
  @ViewBuilder
  func leadingPresentationPlacement() -> some View {
    if #available(iOS 27.0, *) {
      presentationPlacement(.leading)
    } else {
      self
    }
  }
}
