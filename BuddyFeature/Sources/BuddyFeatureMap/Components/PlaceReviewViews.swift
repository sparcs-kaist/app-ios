//
//  PlaceReviewViews.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 14/11/2026.
//

import SwiftUI
import BuddyDomain

/// Five stars filled to `rating`, in the colour of the text around them, as the App Store draws
/// them. Halves round to the nearest half star.
struct StarRatingView: View {
  let rating: Double

  var body: some View {
    HStack(spacing: 1) {
      ForEach(1...5, id: \.self) { star in
        Image(systemName: symbolName(for: star))
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(rating, format: .number.precision(.fractionLength(0...1))) out of 5 stars", bundle: .module))
  }

  private func symbolName(for star: Int) -> String {
    let rounded = (rating * 2).rounded() / 2
    if rounded >= Double(star) { return "star.fill" }
    if rounded >= Double(star) - 0.5 { return "star.leadinghalf.filled" }
    return "star"
  }
}

/// Five stars to tap, in the app's tint. Tapping the one already chosen keeps it, so a rating can't
/// be cleared by accident.
struct StarRatingPicker: View {
  @Binding var rating: Int
  var size: CGFloat = 34

  var body: some View {
    HStack(spacing: size / 3) {
      ForEach(1...5, id: \.self) { star in
        Button {
          rating = star
        } label: {
          Image(systemName: star <= rating ? "star.fill" : "star")
            .font(.system(size: size))
            .foregroundStyle(.tint)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
      }
    }
    .sensoryFeedback(.selection, trigger: rating)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("Rating", bundle: .module))
    .accessibilityValue(Text("\(rating) out of 5 stars", bundle: .module))
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: rating = min(rating + 1, 5)
      case .decrement: rating = max(rating - 1, 1)
      @unknown default: break
      }
    }
  }
}

/// The order a place's reviews are listed in: the App Store's four, in its order.
enum PlaceReviewSort: CaseIterable {
  case helpful
  case favorable
  case critical
  case recent

  var title: String {
    switch self {
    case .helpful: String(localized: "Most Helpful", bundle: .module)
    case .favorable: String(localized: "Most Favorable", bundle: .module)
    case .critical: String(localized: "Most Critical", bundle: .module)
    case .recent: String(localized: "Most Recent", bundle: .module)
    }
  }

  /// Ties fall back to the more upvoted review, then the newer one.
  func sorted(_ reviews: [PlaceReview]) -> [PlaceReview] {
    switch self {
    case .helpful: reviews.sorted { ($0.upvotes, $0.createdAt) > ($1.upvotes, $1.createdAt) }
    case .favorable: reviews.sorted { ($0.rating, $0.upvotes, $0.createdAt) > ($1.rating, $1.upvotes, $1.createdAt) }
    case .critical: reviews.sorted { (-$0.rating, $0.upvotes, $0.createdAt) > (-$1.rating, $1.upvotes, $1.createdAt) }
    case .recent: reviews.sorted { $0.createdAt > $1.createdAt }
    }
  }
}

/// A place's ratings and reviews on its card, laid out as the App Store lays out an app's: a title
/// that opens every review, the average beside its stars, the reviews in a row that scrolls
/// sideways, then stars to tap and a button to write. Shows nothing for a place that has no reviews
/// and doesn't take any, such as a gate.
struct PlaceReviewsSection: View {
  let reviews: [PlaceReview]
  let placeName: String
  let category: CampusPlaceCategory
  let onUpvote: (PlaceReview) -> Void
  /// Stars, 1...5, the text, which may be empty, and any photos.
  let onWrite: (Int, String, [PlacePhoto]) -> Void
  let onDelete: () -> Void

  @State private var sort: PlaceReviewSort = .recent
  /// Review IDs in the order shown. Kept apart from the reviews so that upvoting one while sorted
  /// by upvotes doesn't move it from under the finger; the order is redone when the sort changes.
  @State private var orderedIDs: [String] = []
  @State private var showsAllReviews = false

  private var photos: [PlacePhoto] {
    reviews.flatMap(\.photos)
  }

  private var myReview: PlaceReview? {
    reviews.first(where: \.isMine)
  }

  /// Reviews with something to read or look at. A bare star rating counts toward the average but
  /// gets no card.
  private var writtenReviews: [PlaceReview] {
    reviews.filter { !$0.text.isEmpty || !$0.photos.isEmpty }
  }

  private var orderedReviews: [PlaceReview] {
    let written = writtenReviews
    let ordered = orderedIDs.compactMap { id in written.first { $0.id == id } }
    return ordered.count == written.count ? ordered : sort.sorted(written)
  }

  var body: some View {
    if category.acceptsReviews || !reviews.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        header

        if let summary = PlaceRatingSummary(reviews: reviews) {
          HStack {
            Text(summary.average, format: .number.precision(.fractionLength(1)))
              .font(.system(size: 56, weight: .bold, design: .rounded))
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
              StarRatingView(rating: summary.average)
                .font(.subheadline)
              Text("\(summary.count) Ratings", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .accessibilityElement(children: .combine)
        } else {
          Text("No ratings yet. Be the first to share what you think.", bundle: .module)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        // Photos come between the rating and the reviews they were attached to.
        if !photos.isEmpty {
          ScrollView(.horizontal) {
            HStack(spacing: 8) {
              ForEach(photos) { photo in
                PlacePhotoView(photo: photo, category: category)
                  .frame(width: 130, height: 130)
                  .clipShape(.rect(cornerRadius: 16, style: .continuous))
              }
            }
          }
          .scrollIndicators(.hidden)
          .scrollClipDisabled()
        }

        if !writtenReviews.isEmpty {
          Text(sort.title)
            .font(.footnote.weight(.semibold))

          // Side by side, as the App Store has them: each card leaves the next one peeking in.
          ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 10) {
              ForEach(orderedReviews) { review in
                PlaceReviewCard(review: review, category: category, lineLimit: 6) {
                  onUpvote(review)
                }
                  .containerRelativeFrame(.horizontal) { width, _ in
                    writtenReviews.count == 1 ? width : width * 0.9
                  }
              }
            }
            .scrollTargetLayout()
          }
          .scrollTargetBehavior(.viewAligned)
          .scrollIndicators(.hidden)
          .scrollClipDisabled()
        }

        if category.acceptsReviews {
          PlaceRateControls(placeName: placeName, myReview: myReview, onWrite: onWrite, onDelete: onDelete)
            .padding(.top, 4)
        }

      }
      .onChange(of: sort, initial: true) {
        withAnimation(.snappy) { orderedIDs = sort.sorted(writtenReviews).map(\.id) }
      }
      .onChange(of: writtenReviews.map(\.id)) {
        withAnimation(.snappy) { orderedIDs = sort.sorted(writtenReviews).map(\.id) }
      }
      .sheet(isPresented: $showsAllReviews) {
        PlaceReviewsView(
          reviews: orderedReviews,
          summary: PlaceRatingSummary(reviews: reviews),
          placeName: placeName,
          category: category,
          myReview: myReview,
          sort: $sort,
          onUpvote: onUpvote,
          onWrite: onWrite,
          onDelete: onDelete
        )
      }
    }
  }

  /// The title, with a chevron that opens every review once there are some to open.
  @ViewBuilder
  private var header: some View {
    let title = Text("Ratings & Reviews", bundle: .module)
      .font(.title3.weight(.bold))

    if writtenReviews.isEmpty {
      title
    } else {
      Button {
        showsAllReviews = true
      } label: {
        HStack(spacing: 4) {
          title
          Image(systemName: "chevron.right")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.secondary)
        }
        .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .accessibilityHint(Text("Shows all reviews", bundle: .module))
    }
  }
}

/// Every review of a place on a page of its own, as the App Store's "Ratings & Reviews": the
/// average beside a bar for each number of stars, stars to tap, a button to write, then the reviews
/// in the order picked from the menu.
struct PlaceReviewsView: View {
  /// Already in the order to show.
  let reviews: [PlaceReview]
  let summary: PlaceRatingSummary?
  let placeName: String
  let category: CampusPlaceCategory
  let myReview: PlaceReview?
  @Binding var sort: PlaceReviewSort
  let onUpvote: (PlaceReview) -> Void
  let onWrite: (Int, String, [PlacePhoto]) -> Void
  let onDelete: () -> Void

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          if let summary {
            RatingBreakdown(summary: summary)
            Divider()
          }

          if category.acceptsReviews {
            PlaceRateControls(placeName: placeName, myReview: myReview, onWrite: onWrite, onDelete: onDelete)
          }

          Menu {
            Picker(String(localized: "Sort", bundle: .module), selection: $sort) {
              ForEach(PlaceReviewSort.allCases, id: \.self) { sort in
                Text(sort.title).tag(sort)
              }
            }
          } label: {
            HStack(spacing: 4) {
              Text(sort.title)
              Image(systemName: "chevron.down")
                .imageScale(.small)
            }
            .font(.footnote.weight(.semibold))
          }
          .frame(maxWidth: .infinity, alignment: .trailing)

          LazyVStack(spacing: 12) {
            ForEach(reviews) { review in
              PlaceReviewCard(review: review, category: category, lineLimit: nil) {
                onUpvote(review)
              }
            }
          }
        }
        .padding()
        .contentWidth()
      }
      .navigationTitle(String(localized: "Ratings & Reviews", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .close) {
            dismiss()
          }
        }
      }
    }
  }
}

/// "Tap to Rate" over five stars, then the button that opens the sheet for writing a review.
/// Tapping a star rates the place there and then, keeping any words and photos already there.
private struct PlaceRateControls: View {
  let placeName: String
  let myReview: PlaceReview?
  let onWrite: (Int, String, [PlacePhoto]) -> Void
  let onDelete: () -> Void

  @State private var isComposing = false

  var body: some View {
    VStack(spacing: 10) {
      Text("Tap to Rate", bundle: .module)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)

      StarRatingPicker(
        rating: Binding(
          get: { myReview?.rating ?? 0 },
          set: { onWrite($0, myReview?.text ?? "", myReview?.photos ?? []) }
        ),
        size: 26
      )
      .padding(.bottom, 6)

      Button {
        isComposing = true
      } label: {
        Label(
          myReview.map { !$0.text.isEmpty || !$0.photos.isEmpty } == true
            ? String(localized: "Edit Your Review", bundle: .module)
            : String(localized: "Write a Review", bundle: .module),
          systemImage: "square.and.pencil"
        )
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
      }
      .buttonStyle(.bordered)
      .buttonBorderShape(.capsule)
      .tint(.primary)
    }
    .frame(maxWidth: .infinity)
    .sheet(isPresented: $isComposing) {
      PlaceReviewComposeView(
        placeName: placeName,
        rating: myReview?.rating ?? 0,
        text: myReview?.text ?? "",
        photos: myReview?.photos ?? [],
        onDelete: myReview == nil ? nil : onDelete,
        onSubmit: onWrite
      )
    }
  }
}

/// The big average over "out of 5", beside a bar for each number of stars, five at the top, with
/// the number of ratings under the bars.
private struct RatingBreakdown: View {
  let summary: PlaceRatingSummary

  var body: some View {
    HStack(alignment: .top, spacing: 20) {
      VStack(spacing: 0) {
        Text(summary.average, format: .number.precision(.fractionLength(1)))
          .font(.system(size: 60, weight: .bold, design: .rounded))
        Text("out of 5", bundle: .module)
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .trailing, spacing: 6) {
        Grid(alignment: .trailing, horizontalSpacing: 6, verticalSpacing: 3) {
          ForEach((1...5).reversed(), id: \.self) { stars in
            GridRow {
              HStack(spacing: 1) {
                ForEach(0..<stars, id: \.self) { _ in
                  Image(systemName: "star.fill")
                }
              }
              .font(.system(size: 6))
              .foregroundStyle(.secondary)

              ProgressView(value: Double(summary.distribution[stars - 1]), total: Double(summary.count))
                .tint(.primary)
                .scaleEffect(y: 0.6)
            }
          }
        }
        .accessibilityHidden(true)

        Text("\(summary.count) Ratings", bundle: .module)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .padding(.top, 14)
    }
    .frame(maxWidth: .infinity)
  }
}

/// One review as the App Store shows one: who wrote it in bold, their stars and when, then what
/// they wrote, any photos they attached and the upvote button.
private struct PlaceReviewCard: View {
  let review: PlaceReview
  let category: CampusPlaceCategory
  /// How many lines of the text to show; nil for all of it.
  let lineLimit: Int?
  let onUpvote: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 4) {
        Text(review.authorName)
          .font(.subheadline.weight(.semibold))
        HStack(spacing: 6) {
          StarRatingView(rating: Double(review.rating))
            .font(.caption2)
          Text(review.createdAt, format: .relative(presentation: .named))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if !review.text.isEmpty {
        Text(review.text)
          .font(.subheadline)
          .lineLimit(lineLimit)
          .fixedSize(horizontal: false, vertical: true)
      }

      if !review.photos.isEmpty {
        HStack(spacing: 6) {
          ForEach(review.photos) { photo in
            PlacePhotoView(photo: photo, category: category)
              .frame(width: 84, height: 84)
              .clipShape(.rect(cornerRadius: 12, style: .continuous))
          }
        }
      }

      Spacer(minLength: 0)

      Button(action: onUpvote) {
        HStack(spacing: 6) {
          Image(systemName: review.isUpvoted ? "heart.fill" : "heart")
          Text(review.upvotes, format: .number)
            .contentTransition(.numericText(countsDown: true))
        }
      }
      .tint(review.isUpvoted ? Color.upvote : .primary)
      .buttonStyle(.glass)
      .animation(.spring, value: review.isUpvoted)
      .sensoryFeedback(.selection, trigger: review.isUpvoted)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .accessibilityLabel(Text("Upvote", bundle: .module))
      .accessibilityValue(Text(review.upvotes, format: .number))
      .accessibilityAddTraits(review.isUpvoted ? .isSelected : [])
    }
    // Fill the row's height so every card is as tall as the tallest.
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(16)
    .background(.fill.quaternary, in: .rect(cornerRadius: 20, style: .continuous))
  }
}

private extension CampusPlaceCategory {
  /// Stops, gates and car parks are passed through, not reviewed.
  var acceptsReviews: Bool {
    switch self {
    case .olevStop, .gate, .parking: false
    default: true
    }
  }
}
