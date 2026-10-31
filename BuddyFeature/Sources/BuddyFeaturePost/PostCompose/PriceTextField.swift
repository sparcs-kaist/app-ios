//
//  PriceTextField.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import UIKit

/// A number field that regroups its digits as they're typed ("125,000" + "0" → "1,250,000").
/// SwiftUI's `TextField` only formats when editing ends, and reformatting its text binding on each
/// change races the keyboard and drops digits; here the edit and the regrouping happen together.
struct PriceTextField: UIViewRepresentable {
  let placeholder: String
  @Binding var value: Int?
  /// Mirrors the field's first-responder state; set it to move the keyboard here.
  @Binding var isFocused: Bool
  var font: UIFont = .preferredFont(forTextStyle: .title3)
  /// Twelve digits: up to 999,999,999,999.
  var maxDigits = 12

  func makeUIView(context: Context) -> UITextField {
    let field = UITextField()
    field.placeholder = placeholder
    field.keyboardType = .numberPad
    field.font = font
    field.adjustsFontForContentSizeCategory = true
    field.delegate = context.coordinator
    field.text = Self.text(for: value)
    field.setContentHuggingPriority(.defaultLow, for: .horizontal)
    field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return field
  }

  func updateUIView(_ field: UITextField, context: Context) {
    context.coordinator.parent = self
    let text = Self.text(for: value)
    if field.text != text {
      field.text = text
    }
    if isFocused && !field.isFirstResponder {
      DispatchQueue.main.async { field.becomeFirstResponder() }
    } else if !isFocused && field.isFirstResponder {
      DispatchQueue.main.async { field.resignFirstResponder() }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  static func text(for value: Int?) -> String {
    value?.formatted(.number.locale(Locale(identifier: "en_US"))) ?? ""
  }

  static func isDigit(_ character: Character) -> Bool {
    character.isASCII && character.isWholeNumber
  }

  final class Coordinator: NSObject, UITextFieldDelegate {
    var parent: PriceTextField

    init(parent: PriceTextField) {
      self.parent = parent
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
      if !parent.isFocused { parent.isFocused = true }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
      if parent.isFocused { parent.isFocused = false }
    }

    func textField(
      _ textField: UITextField,
      shouldChangeCharactersIn range: NSRange,
      replacementString string: String
    ) -> Bool {
      let current = textField.text ?? ""
      guard var swiftRange = Range(range, in: current) else { return false }
      // A delete key press that takes only a separator would regroup to the same text and leave
      // the cursor where it was, so it takes the neighbouring digit too: the one before it for
      // backspace, the one after it for forward delete. A selection is deleted as selected.
      if string.isEmpty, range.length == 1,
         !current[swiftRange].contains(where: PriceTextField.isDigit),
         let selection = textField.selectedTextRange, selection.isEmpty {
        let cursor = textField.offset(from: textField.beginningOfDocument, to: selection.start)
        if cursor == range.location + 1,
           let digit = current[..<swiftRange.lowerBound].lastIndex(where: PriceTextField.isDigit) {
          swiftRange = digit..<swiftRange.upperBound
        } else if cursor == range.location,
                  let digit = current[swiftRange.upperBound...].firstIndex(where: PriceTextField.isDigit) {
          swiftRange = swiftRange.lowerBound..<current.index(after: digit)
        }
      }
      let edited = current.replacingCharacters(in: swiftRange, with: string)
      // Digits after the cursor, so it can be put back in the same place among them.
      let digitsAfter = current[swiftRange.upperBound...].filter(PriceTextField.isDigit).count

      let digits = String(edited.filter(PriceTextField.isDigit).prefix(parent.maxDigits))
      let value = Int(digits)
      let text = PriceTextField.text(for: value)
      textField.text = text
      parent.value = value

      // Restore the cursor: the same number of digits after it as before the edit.
      var position = text.endIndex
      var remaining = digitsAfter
      while remaining > 0, position > text.startIndex {
        position = text.index(before: position)
        if PriceTextField.isDigit(text[position]) { remaining -= 1 }
      }
      let offset = text.distance(from: text.startIndex, to: position)
      if let cursor = textField.position(from: textField.beginningOfDocument, offset: offset) {
        textField.selectedTextRange = textField.textRange(from: cursor, to: cursor)
      }
      textField.sendActions(for: .editingChanged)
      return false
    }
  }
}
