//
//  PriceTextFieldTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import UIKit
import Testing
@testable import BuddyFeaturePost

extension PostFeatureTests {
  /// Types into the price field the way the keyboard does: one edit at a time, through the
  /// delegate, which regroups the digits and moves the cursor.
  @Suite("Price field")
  @MainActor
  struct PriceTextFieldTests {
    private final class Box {
      var value: Int?
      var isFocused = true
    }

    private let box = Box()
    private let field = UITextField()
    private let coordinator: PriceTextField.Coordinator

    init() {
      let box = box
      let parent = PriceTextField(
        placeholder: "Price",
        value: Binding(get: { box.value }, set: { box.value = $0 }),
        isFocused: Binding(get: { box.isFocused }, set: { box.isFocused = $0 })
      )
      coordinator = parent.makeCoordinator()
      field.delegate = coordinator
    }

    /// Replaces `range` (characters, counted in the field's current text) with `string`.
    private func edit(_ range: NSRange, with string: String) {
      _ = coordinator.textField(field, shouldChangeCharactersIn: range, replacementString: string)
    }

    private func type(_ digits: String) {
      for digit in digits {
        edit(NSRange(location: field.text?.utf16.count ?? 0, length: 0), with: String(digit))
      }
    }

    /// Deletes the last character, as the delete key does with the cursor at the end.
    private func backspace() {
      let length = field.text?.utf16.count ?? 0
      edit(NSRange(location: length - 1, length: 1), with: "")
    }

    private var cursor: Int? {
      field.selectedTextRange.map { field.offset(from: field.beginningOfDocument, to: $0.start) }
    }

    @Test func groupsDigitsAsTheyAreTyped() {
      type("1250000")
      #expect(field.text == "1,250,000")
      #expect(box.value == 1_250_000)
    }

    @Test func regroupsAfterADelete() {
      type("1250000")
      backspace()
      backspace()
      #expect(field.text == "12,500")
      #expect(box.value == 12_500)
    }

    @Test func clearingLeavesNoPrice() {
      type("7")
      backspace()
      #expect(field.text == "")
      #expect(box.value == nil)
    }

    @Test func ignoresAnythingButDigits() {
      type("12")
      edit(NSRange(location: 2, length: 0), with: "a.-٣")
      #expect(field.text == "12")
      #expect(box.value == 12)
    }

    @Test func capsTheNumberOfDigits() {
      type("12345678901234")
      #expect(box.value == 123_456_789_012)
    }

    @Test func keepsTheCursorAmongTheSameDigits() {
      type("125000")
      // "125,000" with the cursor after "12" (offset 2): typing 9 gives "1,295,000",
      // and the four digits after the cursor stay after it.
      edit(NSRange(location: 2, length: 0), with: "9")
      #expect(field.text == "1,295,000")
      #expect(cursor == 4)
    }
  }
}
