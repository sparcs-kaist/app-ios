import SwiftUI

struct PlaceSheetTitle: View {
  let title: String
  let subtitle: String
  var floor: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      ScrollingPlaceTitle(title: title)
        .font(.title2.weight(.bold))
        .accessibilityAddTraits(.isHeader)
      PlaceSubtitle(subtitle: subtitle, floor: floor)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct PlaceSubtitle: View {
  let subtitle: String
  var floor: String?

  var body: some View {
    HStack(spacing: 4) {
      Text(subtitle)
        .lineLimit(1)
      if let floor, !floor.isEmpty {
        Text(verbatim: "·")
          .accessibilityHidden(true)
        Text(floor)
          .fixedSize(horizontal: true, vertical: false)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

private struct ScrollingPlaceTitle: View {
  let title: String

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.layoutDirection) private var layoutDirection
  @State private var textWidth: CGFloat = 0
  @State private var startedAt = Date.now

  var body: some View {
    Text(title)
      .lineLimit(1)
      .hidden()
      .frame(maxWidth: .infinity, alignment: .leading)
      .overlay {
        GeometryReader { proxy in
          if textWidth > proxy.size.width, !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
              HStack(spacing: 32) {
                Text(title).fixedSize()
                Text(title).fixedSize()
              }
              .offset(x: offset(at: context.date))
              .frame(width: proxy.size.width, alignment: .leading)
            }
          } else {
            Text(title)
              .lineLimit(1)
              .frame(width: proxy.size.width, alignment: .leading)
          }
        }
      }
      .background {
        Text(title)
          .fixedSize()
          .hidden()
          .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
          } action: { width in
            textWidth = width
            startedAt = .now
          }
      }
      .clipped()
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.size.width
      } action: { _ in
        startedAt = .now
      }
      .onChange(of: title) { _, _ in startedAt = .now }
      .onChange(of: reduceMotion) { _, _ in startedAt = .now }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(title))
  }

  private func offset(at date: Date) -> CGFloat {
    let distance = textWidth + 32
    let duration = distance / 30
    let elapsed = max(0, date.timeIntervalSince(startedAt))
    let progress = max(0, elapsed.truncatingRemainder(dividingBy: duration + 1.5) - 1.5)
    return (layoutDirection == .rightToLeft ? 1 : -1) * progress * 30
  }
}
