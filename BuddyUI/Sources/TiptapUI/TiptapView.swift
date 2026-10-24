import SwiftUI
import TiptapKit

/// Renders a ``TiptapLayout`` natively.
///
/// Links (inline and bookmarks) go through the `openURL` environment action, and
/// images through ``SwiftUICore/View/tiptapImage(_:)`` when the host supplies its
/// own loader.
public struct TiptapView: View {
  let layout: TiptapLayout

  public init(_ layout: TiptapLayout) {
    self.layout = layout
  }

  public var body: some View {
    TiptapBlockStack(blocks: layout.blocks, spacing: 12)
    #if !os(watchOS)
      .textSelection(.enabled)
    #endif
  }
}

// MARK: - Image customisation

/// Builds the view for an image block.
public struct TiptapImageContent: Sendable {
  let make: @MainActor @Sendable (TiptapImage) -> AnyView
}

extension EnvironmentValues {
  @Entry var tiptapImageContent: TiptapImageContent? = nil
}

extension View {
  /// Replaces the default `AsyncImage` used for image blocks, e.g. with a caching loader.
  public func tiptapImage<Content: View>(
    @ViewBuilder _ content: @escaping @MainActor @Sendable (TiptapImage) -> Content
  ) -> some View {
    environment(\.tiptapImageContent, TiptapImageContent { AnyView(content($0)) })
  }
}

// MARK: - Blocks

struct TiptapBlockStack: View {
  let blocks: [TiptapBlock]
  let spacing: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: spacing) {
      ForEach(blocks) { block in
        TiptapBlockView(block: block)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct TiptapBlockView: View {
  let block: TiptapBlock

  var body: some View {
    switch block.kind {
    case .paragraph(let text):
      // A blank paragraph keeps its line of height, as it does in the editor.
      Text(text.characters.isEmpty ? AttributedString(" ") : text)
        .fixedSize(horizontal: false, vertical: true)

    case .heading(let level, let text):
      Text(text)
        .font(Self.headingFont(level: level))
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)

    case .codeBlock(let code, _):
      TiptapCodeBlockView(code: code)

    case .image(let image):
      TiptapImageView(image: image)

    case .bookmark(let bookmark):
      TiptapBookmarkView(bookmark: bookmark)

    case .blockquote(let blocks):
      TiptapBlockquoteView(blocks: blocks)

    case .list(let list):
      TiptapListView(list: list)

    case .horizontalRule:
      Divider()
        .padding(.vertical, 4)
    }
  }

  private static func headingFont(level: Int) -> Font {
    switch level {
    case 1: .title2.bold()
    case 2: .title3.bold()
    default: .headline
    }
  }
}

struct TiptapCodeBlockView: View {
  let code: String

  var body: some View {
    ScrollView(.horizontal) {
      Text(code)
        .font(.callout.monospaced())
        .fixedSize()
        .padding(12)
    }
    .scrollIndicators(.hidden)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.fill.tertiary, in: .rect(cornerRadius: 10))
  }
}

struct TiptapBlockquoteView: View {
  let blocks: [TiptapBlock]

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Capsule()
        .fill(.tertiary)
        .frame(width: 3)
      TiptapBlockStack(blocks: blocks, spacing: 8)
        .foregroundStyle(.secondary)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct TiptapListView: View {
  let list: TiptapList

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(list.items) { item in
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(item.marker)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .accessibilityHidden(!list.isOrdered)
          TiptapBlockStack(blocks: item.blocks, spacing: 6)
        }
      }
    }
  }
}

struct TiptapImageView: View {
  let image: TiptapImage

  @Environment(\.tiptapImageContent) private var customContent

  var body: some View {
    Group {
      if let customContent {
        customContent.make(image)
      } else {
        AsyncImage(url: image.url) { phase in
          switch phase {
          case .success(let loaded):
            loaded
              .resizable()
              .aspectRatio(contentMode: .fit)
          case .failure:
            placeholder(systemImage: "photo.badge.exclamationmark")
          default:
            placeholder(systemImage: nil)
          }
        }
        .clipShape(.rect(cornerRadius: 8))
      }
    }
    .frame(maxWidth: image.width ?? .infinity, alignment: .leading)
    .accessibilityLabel(image.alt ?? "")
  }

  private func placeholder(systemImage: String?) -> some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(.fill.tertiary)
      .aspectRatio(4 / 3, contentMode: .fit)
      .overlay {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.title2)
            .foregroundStyle(.secondary)
        } else {
          ProgressView()
        }
      }
  }
}

struct TiptapBookmarkView: View {
  let bookmark: TiptapBookmark

  @Environment(\.openURL) private var openURL

  var body: some View {
    Button {
      openURL(bookmark.url)
    } label: {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          Text(bookmark.displayTitle)
            .font(.headline)
          Image(systemName: "chevron.right")
            .font(.caption.bold())
            .foregroundStyle(.secondary)
        }
        Text(bookmark.url.absoluteString)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.fill.tertiary, in: .rect(cornerRadius: 12))
      .contentShape(.rect(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isLink)
  }
}
