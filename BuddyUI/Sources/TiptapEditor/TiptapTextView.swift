#if os(iOS)
import UIKit

/// A rich text view behaving like Notes: the system formatting panel (limited to what Tiptap
/// can store), Writing Tools, lists, and photos inline in the text.
final class TiptapTextView: UITextView {
  /// Called after every edit, including programmatic ones such as inserting a photo.
  var onChange: (() -> Void)?

  init() {
    super.init(frame: .zero, textContainer: nil)
    allowsEditingTextAttributes = true
    textFormattingConfiguration = .tiptap
    typingAttributes = TiptapBlockStyle.body.attributes
    writingToolsBehavior = .complete
    allowedWritingToolsResultOptions = [.plainText, .richText, .list]
    backgroundColor = .clear
    // Sized by its content and scrolled by the page around it, so the title and the body
    // scroll together as one note.
    isScrollEnabled = false
    textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    // Lines up with the title field above it.
    textContainer.lineFragmentPadding = 0
  }

  required init?(coder: NSCoder) {
    fatalError("TiptapTextView is not archived")
  }

  // MARK: - Formatting panel

  private weak var formattingController: UITextFormattingViewController?

  /// Shows Notes' formatting panel for the selection. With room for it, a popover from the
  /// button that opened it, its controls in compact rows, while the keyboard stays up; otherwise
  /// a half-height sheet that leaves the text visible above it.
  func showFormatting(from anchor: CGRect?) {
    guard formattingController == nil, let presenter = presentingViewController else { return }
    let controller = UITextFormattingViewController(configuration: .tiptap)
    controller.delegate = self
    controller.formattingDescriptor = currentFormattingDescriptor
    // The window's width, not this view's: the composer is a sheet, which reads as compact.
    if let anchor, let window, window.traitCollection.horizontalSizeClass == .regular {
      controller.modalPresentationStyle = .popover
      if let popover = controller.popoverPresentationController {
        // SwiftUI's global space is the window's.
        popover.sourceView = window
        popover.sourceRect = anchor
        popover.permittedArrowDirections = [.up, .down]
      }
      formattingController = controller
      let selection = selectedRange
      presenter.present(controller, animated: true) { [weak self] in
        // Stays where it was being written, with the keyboard up beneath the popover.
        if self?.isFirstResponder == false {
          self?.becomeFirstResponder()
        }
        self?.selectedRange = selection
      }
      return
    }
    if let sheet = controller.sheetPresentationController {
      sheet.detents = [.medium()]
      sheet.largestUndimmedDetentIdentifier = .medium
      sheet.prefersGrabberVisible = true
    }
    formattingController = controller
    // The keyboard would cover the panel, so it's swapped for an empty input view while the
    // panel is open: the text stays selectable, and the cursor movable, with no keyboard.
    // The keyboard goes down first; once the panel is up the text is focused again with no
    // keyboard. (Reloading input views mid-presentation cancels the panel.)
    let selection = selectedRange
    resignFirstResponder()
    presenter.present(controller, animated: true) { [weak self] in
      self?.setKeyboardSuppressed(true)
      self?.selectedRange = selection
    }
  }

  private var isKeyboardSuppressed = false
  private lazy var emptyInputView = UIView(frame: .zero)

  private func setKeyboardSuppressed(_ suppressed: Bool) {
    guard suppressed != isKeyboardSuppressed else { return }
    isKeyboardSuppressed = suppressed
    inputView = suppressed ? emptyInputView : nil
    if isFirstResponder {
      reloadInputViews()
    } else if suppressed {
      becomeFirstResponder()
    }
  }

  /// The front-most view controller this view can present from.
  private var presentingViewController: UIViewController? {
    var responder: UIResponder? = self
    while let next = responder?.next, !(next is UIViewController) {
      responder = next
    }
    var controller = responder?.next as? UIViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  /// What the panel shows as selected: the selection's formatting, or what's about to be typed.
  private var currentFormattingDescriptor: UITextFormattingViewController.FormattingDescriptor {
    let attributes: [NSAttributedString.Key: Any]
    var descriptor: UITextFormattingViewController.FormattingDescriptor
    if selectedRange.length > 0 {
      descriptor = .init(string: textStorage, range: selectedRange)
      attributes = textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
    } else {
      descriptor = .init(attributes: typingAttributes)
      attributes = typingAttributes
    }
    descriptor.formattingStyleKey = TiptapBlockStyle.of(attributes).rawValue
    return descriptor
  }

  /// Keeps an open panel in step with the selection.
  func selectionDidChange() {
    // A panel swiped away rather than closed may not report finishing; bring the keyboard back.
    if formattingController == nil {
      setKeyboardSuppressed(false)
    }
    formattingController?.formattingDescriptor = currentFormattingDescriptor
  }

  fileprivate func apply(_ change: UITextFormattingViewController.ChangeValue) {
    switch change {
    case .bold(let isOn):
      updateFonts { $0.withTrait(.traitBold, enabled: isOn) }
    case .italic(let isOn):
      updateFonts { $0.withTrait(.traitItalic, enabled: isOn) }
    case .underline(let isOn):
      setAttribute(.underlineStyle, isOn ? NSUnderlineStyle.single.rawValue : nil)
    case .strikethrough(let isOn):
      setAttribute(.strikethroughStyle, isOn ? NSUnderlineStyle.single.rawValue : nil)
    case .textColor(let color):
      setAttribute(.foregroundColor, color)
    case .textList(let list):
      setList(list.map(Self.textList(for:)), for: selectedParagraphRange, removingAll: true)
    case .formattingStyle(let key):
      if let style = TiptapBlockStyle(rawValue: key) {
        setBlockStyle(style)
      }
    default:
      // Fonts, sizes, alignment and highlight aren't offered: Tiptap can't store them.
      break
    }
    formattingController?.formattingDescriptor = currentFormattingDescriptor
    onChange?()
  }

  private static func textList(for list: UITextFormattingViewController.TextList) -> NSTextList {
    switch list {
    case .decimal: NSTextList(markerFormat: .decimal, options: 0)
    case .hyphen: NSTextList(markerFormat: .hyphen, options: 0)
    default: NSTextList(markerFormat: .disc, options: 0)
    }
  }

  /// Sets or removes an attribute on the selection, or on what's typed next.
  private func setAttribute(_ key: NSAttributedString.Key, _ value: Any?) {
    if selectedRange.length > 0 {
      if let value {
        textStorage.addAttribute(key, value: value, range: selectedRange)
      } else {
        textStorage.removeAttribute(key, range: selectedRange)
      }
    }
    typingAttributes[key] = value
  }

  private func updateFonts(_ transform: (UIFont) -> UIFont) {
    if selectedRange.length > 0 {
      textStorage.beginEditing()
      textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
        let font = value as? UIFont ?? TiptapBlockStyle.body.font
        textStorage.addAttribute(.font, value: transform(font), range: range)
      }
      textStorage.endEditing()
    }
    let font = typingAttributes[.font] as? UIFont ?? TiptapBlockStyle.body.font
    typingAttributes[.font] = transform(font)
  }

  /// Restyles whole paragraphs, keeping italic the author applied. Bold isn't kept: a
  /// heading's weight would otherwise turn into bold text when it goes back to body.
  private func setBlockStyle(_ style: TiptapBlockStyle) {
    let restyle = { (font: UIFont?) -> UIFont in
      let isItalic = font?.fontDescriptor.symbolicTraits.contains(.traitItalic) ?? false
      return isItalic ? style.font.withTrait(.traitItalic, enabled: true) : style.font
    }
    let range = selectedParagraphRange
    if range.length > 0 {
      textStorage.beginEditing()
      textStorage.addAttribute(.tiptapBlockStyle, value: style.rawValue, range: range)
      textStorage.enumerateAttribute(.font, in: range) { value, subrange, _ in
        textStorage.addAttribute(.font, value: restyle(value as? UIFont), range: subrange)
      }
      textStorage.endEditing()
    }
    typingAttributes[.tiptapBlockStyle] = style.rawValue
    typingAttributes[.font] = restyle(typingAttributes[.font] as? UIFont)
  }

  /// The ranges of the paragraphs the selection touches.
  private var selectedParagraphRange: NSRange {
    (textStorage.string as NSString).paragraphRange(for: selectedRange)
  }

  /// Turns the selected paragraphs into a bulleted list, or back into paragraphs if they all are.
  func toggleBulletList() {
    let range = selectedParagraphRange
    let isList = range.length > 0
      ? textStorage.attribute(.paragraphStyle, at: range.location, effectiveRange: nil).flatMap { ($0 as? NSParagraphStyle)?.textLists.isEmpty == false } ?? false
      : (typingAttributes[.paragraphStyle] as? NSParagraphStyle)?.textLists.isEmpty == false
    setList(isList ? nil : NSTextList(markerFormat: .disc, options: 0), for: range)
  }

  /// Applies `list` to every paragraph in `range`, or with `nil` removes the innermost list
  /// (or every list, with `removingAll`).
  private func setList(_ list: NSTextList?, for range: NSRange, removingAll: Bool = false) {
    let style = { (current: NSParagraphStyle?) -> NSParagraphStyle in
      let style = (current?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
      if let list {
        style.textLists = [list]
      } else {
        style.textLists = removingAll ? [] : Array(style.textLists.dropLast())
      }
      let level = CGFloat(style.textLists.count)
      style.headIndent = Self.listIndent * level
      style.firstLineHeadIndent = Self.listIndent * level
      return style
    }

    if range.length > 0 {
      textStorage.beginEditing()
      textStorage.enumerateAttribute(.paragraphStyle, in: range) { value, subrange, _ in
        textStorage.addAttribute(.paragraphStyle, value: style(value as? NSParagraphStyle), range: subrange)
      }
      textStorage.endEditing()
    }
    typingAttributes[.paragraphStyle] = style(typingAttributes[.paragraphStyle] as? NSParagraphStyle)
    onChange?()
  }

  private static let listIndent: CGFloat = 24

  // MARK: - Typing behaviour

  /// Handles Return the way Notes does. Returns `false` when it made the edit itself.
  func handleReturn(in range: NSRange) -> Bool {
    let paragraph = (textStorage.string as NSString).paragraphRange(for: range)
    let attributes = textStorage.length > 0 && paragraph.location < textStorage.length
      ? textStorage.attributes(at: paragraph.location, effectiveRange: nil)
      : typingAttributes
    let content = (textStorage.string as NSString).substring(with: paragraph).trimmingCharacters(in: .newlines)

    // Return on an empty list item ends the list (or steps out one level).
    if content.isEmpty, (attributes[.paragraphStyle] as? NSParagraphStyle)?.textLists.isEmpty == false {
      setList(nil, for: paragraph)
      return false
    }

    // After a title or heading, the next line is body text again.
    if TiptapBlockStyle.of(attributes).headingLevel != nil {
      resetsStyleAfterEdit = true
    }
    return true
  }

  private var resetsStyleAfterEdit = false

  func textDidChange() {
    if resetsStyleAfterEdit {
      resetsStyleAfterEdit = false
      var attributes = TiptapBlockStyle.body.attributes
      attributes[.paragraphStyle] = typingAttributes[.paragraphStyle]
      typingAttributes = attributes
    }
    adoptPlainImageAttachments()
    alignIndentWithLists()
    onChange?()
  }

  /// Keeps the current paragraph's indent in step with its list depth. UIKit ends a list on
  /// Return in an empty item by itself, and leaves the list's indent behind when it does.
  private func alignIndentWithLists() {
    let aligned = { (style: NSParagraphStyle) -> NSParagraphStyle? in
      let indent = Self.listIndent * CGFloat(style.textLists.count)
      guard style.headIndent != indent || style.firstLineHeadIndent != indent else { return nil }
      let fixed = (style.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
      fixed.headIndent = indent
      fixed.firstLineHeadIndent = indent
      return fixed
    }

    let range = selectedParagraphRange
    if range.length > 0 {
      var fixes: [(NSRange, NSParagraphStyle)] = []
      textStorage.enumerateAttribute(.paragraphStyle, in: range) { value, subrange, _ in
        if let style = value as? NSParagraphStyle, let fixed = aligned(style) {
          fixes.append((subrange, fixed))
        }
      }
      if !fixes.isEmpty {
        let selection = selectedRange
        textStorage.beginEditing()
        fixes.forEach { textStorage.addAttribute(.paragraphStyle, value: $1, range: $0) }
        textStorage.endEditing()
        selectedRange = selection
      }
    }
    if let style = typingAttributes[.paragraphStyle] as? NSParagraphStyle, let fixed = aligned(style) {
      typingAttributes[.paragraphStyle] = fixed
    }
  }

  // MARK: - Photos

  /// Inserts photos at the selection, each on a line of its own.
  func insertImages(_ images: [UIImage]) {
    guard !images.isEmpty else { return }
    let string = textStorage.string as NSString
    var location = selectedRange.location
    var attributes = typingAttributes
    attributes[.tiptapBlockStyle] = TiptapBlockStyle.body.rawValue
    attributes[.font] = TiptapBlockStyle.body.font

    let insertion = NSMutableAttributedString()
    let atLineStart = location == 0 || string.character(at: location - 1) == 0x0A
    if !atLineStart {
      insertion.append(NSAttributedString(string: "\n", attributes: attributes))
    }
    for image in images {
      let attachment = NSMutableAttributedString(attachment: TiptapImageAttachment(image: image))
      attachment.addAttributes(attributes, range: NSRange(location: 0, length: attachment.length))
      insertion.append(attachment)
      insertion.append(NSAttributedString(string: "\n", attributes: attributes))
    }

    textStorage.replaceCharacters(in: selectedRange, with: insertion)
    location += insertion.length
    selectedRange = NSRange(location: location, length: 0)
    typingAttributes = attributes
    textDidChange()
    scrollRangeToVisible(selectedRange)
  }

  override func paste(_ sender: Any?) {
    let pasteboard = UIPasteboard.general
    // Pasted photos become the same attachments as picked ones, so they upload with the post.
    if pasteboard.hasImages, !pasteboard.hasStrings, let images = pasteboard.images {
      insertImages(images)
    } else {
      super.paste(sender)
    }
  }

  /// Pasted or dropped rich text can carry photos as plain attachments, which the converter
  /// would drop. Done after the change lands, since UIKit pastes asynchronously.
  private func adoptPlainImageAttachments() {
    var replacements: [(NSRange, TiptapImageAttachment)] = []
    textStorage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textStorage.length)) { value, subrange, _ in
      guard let attachment = value as? NSTextAttachment, !(attachment is TiptapImageAttachment),
            let image = attachment.image
              ?? attachment.contents.flatMap(UIImage.init(data:))
              ?? attachment.fileWrapper?.regularFileContents.flatMap(UIImage.init(data:))
      else { return }
      replacements.append((subrange, TiptapImageAttachment(image: image)))
    }
    guard !replacements.isEmpty else { return }
    textStorage.beginEditing()
    replacements.forEach { textStorage.addAttribute(.attachment, value: $1, range: $0) }
    textStorage.endEditing()
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(paste(_:)), UIPasteboard.general.hasImages {
      return true
    }
    return super.canPerformAction(action, withSender: sender)
  }
}

extension TiptapTextView: UITextFormattingViewController.Delegate {
  func textFormattingViewController(
    _ viewController: UITextFormattingViewController,
    didChangeValue changeValue: UITextFormattingViewController.ChangeValue
  ) {
    apply(changeValue)
  }

  func textFormattingDidFinish(_ viewController: UITextFormattingViewController) {
    setKeyboardSuppressed(false)
    becomeFirstResponder()
  }
}

private extension UIFont {
  func withTrait(_ trait: UIFontDescriptor.SymbolicTraits, enabled: Bool) -> UIFont {
    var traits = fontDescriptor.symbolicTraits
    if enabled {
      traits.insert(trait)
    } else {
      traits.remove(trait)
    }
    guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
    return UIFont(descriptor: descriptor, size: pointSize)
  }
}
#endif
