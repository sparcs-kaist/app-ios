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
    value?.formatted(.number) ?? ""
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
      if string.isEmpty,
         !current[swiftRange].contains(where: \.isWholeNumber),
         let digit = current[..<swiftRange.lowerBound].lastIndex(where: \.isWholeNumber) {
        swiftRange = digit..<swiftRange.upperBound
      }
      let edited = current.replacingCharacters(in: swiftRange, with: string)
      // Digits after the cursor, so it can be put back in the same place among them.
      let digitsAfter = current[swiftRange.upperBound...].filter(\.isWholeNumber).count

      let digits = String(edited.filter { $0.isASCII && $0.isWholeNumber }.prefix(parent.maxDigits))
      let value = Int(digits)
      let text = PriceTextField.text(for: value)
      textField.text = text
      parent.value = value

      // Restore the cursor: the same number of digits after it as before the edit.
      var position = text.endIndex
      var remaining = digitsAfter
      while remaining > 0, position > text.startIndex {
        position = text.index(before: position)
        if text[position].isWholeNumber { remaining -= 1 }
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
