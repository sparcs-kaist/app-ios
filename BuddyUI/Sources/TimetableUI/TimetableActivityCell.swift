import SwiftUI
import WidgetKit
import BuddyDomain

struct TimetableActivityCell: View {
  let activity: TimetableActivity
  let placement: TimetablePlacement
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4)
          .fill(backgroundColor)
          .widgetAccentable()
          .opacity(renderingMode == .accented ? 0.2 : 1)
        VStack(alignment: .leading, spacing: placement == .widget ? 2 : 4) {
          Text(activity.title)
            .font(.caption.weight(.medium))
            .lineLimit(3)
          if geometry.size.height > 40, !activity.location.isEmpty {
            Text(activity.location)
              .font(.caption2)
              .lineLimit(2)
              .opacity(0.8)
          }
        }
        .padding(6)
        .foregroundStyle(activity.textColor)
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
      .clipped()
      .modifier(TimetableGlassModifier(placement: placement, colorScheme: colorScheme, cellColor: activity.backgroundColor))
    }
    .contentShape(.rect)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(activity.title), \(activity.location), \(TimetableTimeSelection.formattedTime(activity.begin)) – \(TimetableTimeSelection.formattedTime(activity.end))"))
    .accessibilityIdentifier("activity.cell.\(activity.id)")
    .modifier(ActivityPopoverModifier(activity: activity, isEnabled: placement == .view))
  }

  private var backgroundColor: Color {
    if colorScheme == .dark { return activity.backgroundColor.darkTransformedHSB() }
    return placement == .widget ? activity.backgroundColor : .clear
  }
}

private struct ActivityPopoverModifier: ViewModifier {
  let activity: TimetableActivity
  let isEnabled: Bool
  @State private var isPresented = false

  @ViewBuilder
  func body(content: Content) -> some View {
    if isEnabled {
      content
        .onTapGesture { isPresented = true }
        .accessibilityAddTraits(.isButton)
        .popover(isPresented: $isPresented) {
          VStack(alignment: .leading, spacing: 8) {
            Text(activity.title)
              .font(.headline)
            if !activity.location.isEmpty {
              Label(activity.location, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .frame(idealWidth: 240, maxWidth: 280, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)
          .padding()
          .accessibilityIdentifier("activity.details")
          .presentationCompactAdaptation(.popover)
        }
    } else {
      content
    }
  }
}
