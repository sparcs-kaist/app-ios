#if os(iOS)
import SwiftUI
import UIKit
import TiptapKit

/// Drives a ``TiptapEditor``: what it contains, and the actions its host offers around it.
@MainActor
@Observable
public final class TiptapEditorController {
  /// Whether the editor holds no text or photos.
  public private(set) var isEmpty = true
  /// Whether the text is being edited, so the host can make room for the keyboard toolbar.
  public internal(set) var isEditing = false
  /// Bumped on every edit, so the editor's height is re-measured.
  private(set) var revision = 0

  @ObservationIgnored weak var textView: TiptapTextView? {
    didSet {
      if let textView, let pendingText {
        textView.attributedText = pendingText
        self.pendingText = nil
        textDidChange()
      }
    }
  }
  /// Text set before the editor appeared, applied once it does.
  @ObservationIgnored private var pendingText: NSAttributedString?

  public init() {}

  /// The current content, for converting with ``TiptapAttributedStringConverter``.
  public var attributedText: NSAttributedString {
    textView?.attributedText ?? NSAttributedString()
  }

  /// Every photo in the text, in order.
  public var imageAttachments: [TiptapImageAttachment] {
    var attachments: [TiptapImageAttachment] = []
    let text = attributedText
    text.enumerateAttribute(.attachment, in: NSRange(location: 0, length: text.length)) { value, _, _ in
      if let attachment = value as? TiptapImageAttachment {
        attachments.append(attachment)
      }
    }
    return attachments
  }

  /// Replaces the content, e.g. with an existing post to edit.
  public func setAttributedText(_ text: NSAttributedString) {
    if let textView {
      textView.attributedText = text
      textDidChange()
    } else {
      pendingText = text
      isEmpty = text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
  }

  public func insertImages(_ images: [UIImage]) {
    textView?.insertImages(images)
  }

  public func focus() {
    textView?.becomeFirstResponder()
  }

  public func dismissKeyboard() {
    textView?.resignFirstResponder()
  }

  /// Shows Notes' formatting panel for the selection. On a wide screen it's a popover pointing
  /// at `anchor` (the button that opened it, in global coordinates), as on iPad Notes.
  public func showFormatting(from anchor: CGRect? = nil) {
    textView?.showFormatting(from: anchor)
  }

  /// Turns the selected paragraphs into a bulleted list, or back into paragraphs.
  public func toggleBulletList() {
    textView?.toggleBulletList()
  }

  func textDidChange() {
    let text = attributedText
    isEmpty = text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    revision += 1
  }
}

/// A rich text editor that feels like Notes and produces Tiptap documents.
///
/// Formatting comes from the system formatting panel, limited to what Ara's Tiptap schema
/// stores. The host drives it through ``TiptapEditorController``, from its own toolbar.
public struct TiptapEditor: UIViewRepresentable {
  let controller: TiptapEditorController

  public init(controller: TiptapEditorController) {
    self.controller = controller
  }

  public func makeUIView(context: Context) -> UIView {
    let textView = TiptapTextView()
    textView.delegate = context.coordinator
    context.coordinator.controller = controller
    textView.onChange = { [weak controller] in controller?.textDidChange() }
    textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    controller.textView = textView
    return textView
  }

  public func updateUIView(_ uiView: UIView, context: Context) {
    // Read so SwiftUI re-measures the editor whenever its content changes.
    _ = controller.revision
  }

  public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
    guard let width = proposal.width, width > 0 else { return nil }
    let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    return CGSize(width: width, height: max(height, 120))
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  @MainActor
  public final class Coordinator: NSObject, UITextViewDelegate {
    weak var controller: TiptapEditorController?

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
      guard text == "\n", let textView = textView as? TiptapTextView else { return true }
      return textView.handleReturn(in: range)
    }

    public func textViewDidChange(_ textView: UITextView) {
      (textView as? TiptapTextView)?.textDidChange()
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
      (textView as? TiptapTextView)?.selectionDidChange()
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
      controller?.isEditing = true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
      controller?.isEditing = false
    }
  }
}
#endif
