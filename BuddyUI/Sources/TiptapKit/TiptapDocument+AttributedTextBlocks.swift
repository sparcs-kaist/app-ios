import Foundation

/// The text blocks of a document as attributed strings, for processing that keeps formatting
/// (e.g. translation). Each run carries its Tiptap marks, so they can be put back afterwards.
public struct TiptapAttributedTextBlocks: Sendable {
  /// One per paragraph and heading, in the order of ``TiptapDocument/textBlocks``.
  public let blocks: [AttributedString]
  /// The distinct mark sets the runs refer to.
  fileprivate let markSets: [[TiptapMark]]
}

/// Which of a document's mark sets a run had. Kept alongside standard attributes (links,
/// bold, italic…) so marks survive even when only those make it through.
enum TiptapMarkSetAttribute: CodableAttributedStringKey {
  typealias Value = Int
  static let name = "TiptapMarkSet"
}

extension TiptapDocument {
  public var attributedTextBlocks: TiptapAttributedTextBlocks {
    var markSets: [[TiptapMark]] = []
    var blocks: [AttributedString] = []

    func index(of marks: [TiptapMark]) -> Int {
      if let index = markSets.firstIndex(of: marks) { return index }
      markSets.append(marks)
      return markSets.count - 1
    }

    func inline(_ nodes: [TiptapNode]) -> AttributedString {
      var text = AttributedString()
      for node in nodes {
        switch node.type {
        case .text:
          var run = AttributedString(node.text ?? "")
          if !node.marks.isEmpty {
            run[TiptapMarkSetAttribute.self] = index(of: node.marks)
            Self.applyStandardAttributes(for: node.marks, to: &run)
          }
          text.append(run)
        case .hardBreak:
          text.append(AttributedString("\n"))
        default:
          text.append(inline(node.content))
        }
      }
      return text
    }

    func visit(_ nodes: [TiptapNode]) {
      for node in nodes {
        switch node.type {
        case .paragraph, .heading: blocks.append(inline(node.content))
        case .codeBlock: break
        default: visit(node.content)
        }
      }
    }

    visit(content)
    return TiptapAttributedTextBlocks(blocks: blocks, markSets: markSets)
  }

  /// The document with each block's text replaced by `replacements` (processed versions of
  /// `source.blocks`), its marks rebuilt from the runs. Structure and media are kept.
  public func replacingTextBlocks(
    with replacements: [AttributedString],
    source: TiptapAttributedTextBlocks
  ) -> TiptapDocument {
    var index = 0
    func rebuild(_ nodes: [TiptapNode]) -> [TiptapNode] {
      nodes.map { node in
        var node = node
        if node.type == .paragraph || node.type == .heading {
          defer { index += 1 }
          guard index < replacements.count else { return node }
          let media = node.content.filter { $0.type != .text && $0.type != .hardBreak }
          node.content = Self.inlineNodes(from: replacements[index], markSets: source.markSets) + media
        } else if node.type != .codeBlock {
          node.content = rebuild(node.content)
        }
        return node
      }
    }
    return TiptapDocument(content: rebuild(content))
  }

  // MARK: - Helpers

  private static func applyStandardAttributes(for marks: [TiptapMark], to run: inout AttributedString) {
    var intent: InlinePresentationIntent = []
    for mark in marks {
      switch mark.type {
      case .bold: intent.insert(.stronglyEmphasized)
      case .italic: intent.insert(.emphasized)
      case .strike: intent.insert(.strikethrough)
      case .code: intent.insert(.code)
      case .link:
        if let href = mark[attribute: "href"]?.stringValue, let url = URL(string: href) {
          run.link = url
        }
      default: break
      }
    }
    if !intent.isEmpty {
      run.inlinePresentationIntent = intent
    }
  }

  private static func inlineNodes(from text: AttributedString, markSets: [[TiptapMark]]) -> [TiptapNode] {
    var nodes: [TiptapNode] = []
    for run in text.runs {
      let marks = marks(for: run, markSets: markSets)
      let string = String(text[run.range].characters)
      for (lineIndex, line) in string.components(separatedBy: "\n").enumerated() {
        if lineIndex > 0 {
          nodes.append(TiptapNode(type: .hardBreak))
        }
        guard !line.isEmpty else { continue }
        if let last = nodes.last, last.type == .text, last.marks == marks {
          nodes[nodes.count - 1].text = (last.text ?? "") + line
        } else {
          nodes.append(TiptapNode(type: .text, marks: marks, text: line))
        }
      }
    }
    return nodes
  }

  /// The run's original marks when its mark-set tag survived; otherwise what its standard
  /// attributes still say.
  private static func marks(for run: AttributedString.Runs.Run, markSets: [[TiptapMark]]) -> [TiptapMark] {
    if let index = run[TiptapMarkSetAttribute.self], markSets.indices.contains(index) {
      return markSets[index]
    }
    var marks: [TiptapMark] = []
    let intent = run.inlinePresentationIntent ?? []
    if intent.contains(.stronglyEmphasized) { marks.append(TiptapMark(type: .bold)) }
    if intent.contains(.emphasized) { marks.append(TiptapMark(type: .italic)) }
    if intent.contains(.strikethrough) { marks.append(TiptapMark(type: .strike)) }
    if intent.contains(.code) { marks.append(TiptapMark(type: .code)) }
    if let link = run.link {
      marks.append(TiptapMark(type: .link, attrs: ["href": .string(link.absoluteString)]))
    }
    return marks
  }
}

// MARK: - Restoring formatting onto plain translations

/// A linked or styled phrase in a block, to be found again in the block's translation.
public struct TiptapMarkedRun: Sendable {
  public let text: String
  let attributes: AttributeContainer
}

extension TiptapAttributedTextBlocks {
  /// The phrases in a block that carry marks, in order.
  public func markedRuns(inBlock index: Int) -> [TiptapMarkedRun] {
    guard blocks.indices.contains(index) else { return [] }
    let block = blocks[index]
    return block.runs.compactMap { run in
      guard run[TiptapMarkSetAttribute.self] != nil else { return nil }
      let text = String(block[run.range].characters).trimmingCharacters(in: .whitespacesAndNewlines)
      return text.isEmpty ? nil : TiptapMarkedRun(text: text, attributes: run.attributes)
    }
  }

  /// Whether `text` still carries any marks, i.e. the translator kept the attribute runs.
  public static func carriesMarks(_ text: AttributedString) -> Bool {
    text.runs.contains { run in
      run[TiptapMarkSetAttribute.self] != nil || run.link != nil || run.inlinePresentationIntent != nil
    }
  }

  /// A plain translation with each marked phrase's formatting put back where its own
  /// translation (or, failing that, its original text, as with URLs and names) appears.
  /// Phrases that can't be found are left unmarked rather than misplaced.
  public static func restoringMarks(
    _ runs: [(run: TiptapMarkedRun, translation: String)],
    onto translation: String
  ) -> AttributedString {
    var result = AttributedString(translation)
    var cursor = result.startIndex
    for (run, translatedRun) in runs {
      let candidates = [translatedRun, run.text]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)) }
        .filter { !$0.isEmpty }
      var found: Range<AttributedString.Index>?
      for candidate in candidates {
        // Phrases usually keep their order; look after the previous one first.
        found = result[cursor...].range(of: candidate, options: .caseInsensitive)
          ?? result.range(of: candidate, options: .caseInsensitive)
        if found != nil { break }
      }
      guard let range = found else { continue }
      result[range].setAttributes(run.attributes)
      cursor = range.upperBound
    }
    return result
  }
}
