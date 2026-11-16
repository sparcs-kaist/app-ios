//
//  PlaceComponents.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import BuddyDomain

/// The round, tinted category glyph Apple Maps puts beside every place.
struct PlaceIcon: View {
  let category: CampusPlaceCategory
  var size: CGFloat = 36

  var body: some View {
    Image(systemName: category.symbolName)
      .font(.system(size: size * 0.44, weight: .semibold))
      .foregroundStyle(.white)
      .frame(width: size, height: size)
      .background(category.tint.gradient, in: .circle)
      .accessibilityHidden(true)
  }
}

/// "Open · Closes 19:00" with the status word coloured.
struct OpeningStatusText: View {
  let status: OpeningStatus

  var body: some View {
    if let detail = status.detail {
      Text("\(Text(status.title).foregroundStyle(status.tint).fontWeight(.medium)) · \(detail)", bundle: .module)
    } else {
      Text(status.title)
        .foregroundStyle(status.tint)
        .fontWeight(.medium)
    }
  }
}

/// A place in a list: icon, name, and a line of category, distance and opening status.
struct PlaceRow: View {
  let place: CampusPlace
  let viewModel: CampusMapViewModelProtocol
  var showsPin: Bool = true

  var body: some View {
    HStack(spacing: 12) {
      PlaceIcon(category: place.category, size: 40)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(place.displayName)
            .font(.body.weight(.semibold))
            .lineLimit(1)
          if showsPin && viewModel.isPinned(place) {
            Image(systemName: "pin.fill")
              .font(.caption2)
              .foregroundStyle(.orange)
              .accessibilityLabel(Text("Pinned", bundle: .module))
          }
        }

        HStack(spacing: 4) {
          Text(place.category.title)
          Text(verbatim: "·")
          Text(viewModel.distance(to: place).distanceText)
          if let hours = place.openingHours {
            Text(verbatim: "·")
            Text(hours.status(at: .now).title)
              .foregroundStyle(hours.status(at: .now).tint)
          }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      }

      Spacer(minLength: 0)
    }
    .contentShape(.rect)
  }
}

/// Stands in for a photo until the API serves real ones: a soft gradient keyed to the photo's hue,
/// with the category glyph so a row of them still reads as "this place".
struct PlacePhotoView: View {
  let photo: PlacePhoto
  let category: CampusPlaceCategory

  var body: some View {
    let base = Color(hue: photo.hue, saturation: 0.45, brightness: 0.85)
    let deep = Color(hue: photo.hue, saturation: 0.65, brightness: 0.55)

    LinearGradient(colors: [base, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
      .overlay {
        // The tinted placeholder stays underneath while a real photo loads, or when there is none.
        if let url = photo.url, url.isFileURL, let image = UIImage(contentsOfFile: url.path) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        } else if let url = photo.url {
          AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
          } placeholder: {
            Color.clear
          }
        } else {
          Image(systemName: category.symbolName)
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(.white.opacity(0.55))
        }
      }
      .clipped()
      .overlay(alignment: .bottomLeading) {
        if let caption = photo.caption {
          Text(caption)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(8)
        }
      }
      .accessibilityLabel(Text("Photo", bundle: .module))
  }
}

struct PlaceDetailSection<Content: View>: View {
  var title: String?
  var trailing: AnyView?
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let title {
        HStack {
          Text(title)
            .font(.title3.weight(.bold))
            .accessibilityAddTraits(.isHeader)
          Spacer()
          trailing
        }
      }
      content
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

/// A list section header in Apple Maps' style: bold title with an optional trailing link.
struct MapSectionHeader<Trailing: View>: View {
  let title: String
  @ViewBuilder var trailing: Trailing

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.title3.weight(.bold))
      Spacer()
      trailing
        .font(.subheadline)
    }
  }
}

extension MapSectionHeader where Trailing == EmptyView {
  init(title: String) {
    self.init(title: title) { EmptyView() }
  }
}
