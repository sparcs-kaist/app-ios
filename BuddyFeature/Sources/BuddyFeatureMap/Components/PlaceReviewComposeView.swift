//
//  PlaceReviewComposeView.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 14/11/2026.
//

import SwiftUI
import BuddyDomain

/// The sheet for reviewing a place: stars to tap, then room for a few words. Stars are required,
/// words are not.
struct PlaceReviewComposeView: View {
  let placeName: String
  /// Stars, 1...5, and the text, which may be empty.
  let onSubmit: (Int, String) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var rating: Int
  @State private var text: String

  /// `rating` and `text` are what the user gave before, to carry on from; 0 and empty for a first review.
  init(placeName: String, rating: Int = 0, text: String = "", onSubmit: @escaping (Int, String) -> Void) {
    self.placeName = placeName
    self.onSubmit = onSubmit
    self._rating = State(initialValue: rating)
    self._text = State(initialValue: text)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          VStack(spacing: 8) {
            StarRatingPicker(rating: $rating)
            Text(rating == 0 ? "Tap to Rate" : "\(rating) out of 5 stars", bundle: .module)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .contentTransition(.numericText(value: Double(rating)))
              .animation(.snappy, value: rating)
              .accessibilityHidden(true)
          }
          .frame(maxWidth: .infinity)

          TextField(
            "",
            text: $text,
            prompt: Text("Share your thoughts on \(placeName)...", bundle: .module),
            axis: .vertical
          )
          .lineLimit(4...)
          .padding(14)
          .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
        }
        .padding()
        .contentWidth()
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(String(localized: "Write a Review", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .close) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(role: .confirm) {
            onSubmit(rating, text)
            dismiss()
          } label: {
            Label(String(localized: "Done", bundle: .module), systemImage: "arrow.up")
          }
          .disabled(rating == 0)
        }
      }
    }
  }
}

#Preview {
  PlaceReviewComposeView(placeName: "Kaimaru", onSubmit: { _, _ in })
}
