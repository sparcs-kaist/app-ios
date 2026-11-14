//
//  MenuViews.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import BuddyDomain

/// A cafeteria's menu for today, one meal at a time, opening on the meal being served now.
struct CafeteriaMenuView: View {
  let menu: CafeteriaMenu
  @State private var selectedMeal: MealKind

  init(menu: CafeteriaMenu) {
    self.menu = menu
    let current = MealKind.current()
    let available = menu.meals.map(\.kind)
    _selectedMeal = State(initialValue: available.contains(current) ? current : available.first ?? .lunch)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if menu.meals.count > 1 {
        Picker(String(localized: "Meal", bundle: .module), selection: $selectedMeal.animation(.snappy)) {
          ForEach(menu.meals) { meal in
            Text(meal.kind.title).tag(meal.kind)
          }
        }
        .pickerStyle(.segmented)
      }

      if let meal = menu.meal(selectedMeal) {
        Label {
          Text("\(meal.serving.opens.minutesAsTimeText) – \(meal.serving.closes.minutesAsTimeText)", bundle: .module)
        } icon: {
          Image(systemName: meal.kind.symbolName)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)

        ForEach(meal.courses) { course in
          CafeteriaCourseRow(course: course)
          if course.id != meal.courses.last?.id {
            Divider()
          }
        }
      }
    }
  }
}

struct CafeteriaCourseRow: View {
  let course: CafeteriaCourse

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text(course.name)
          .font(.subheadline.weight(.semibold))
        Spacer()
        Text(course.price.wonText)
          .font(.subheadline.weight(.semibold).monospacedDigit())
      }
      Text(course.dishes.joined(separator: " · "))
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      if let calories = course.calories {
        Text("\(calories) kcal", bundle: .module)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
  }
}

/// A restaurant's menu: popular dishes first, then every section.
struct RestaurantMenuView: View {
  let menu: RestaurantMenu
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(isExpanded ? menu.sections : [popularSection]) { section in
        VStack(alignment: .leading, spacing: 8) {
          Text(section.title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
          ForEach(section.items) { item in
            RestaurantMenuItemRow(item: item, showsBadge: isExpanded)
          }
        }
      }

      Button {
        withAnimation(.snappy) { isExpanded.toggle() }
      } label: {
        Text(isExpanded ? String(localized: "Show Less", bundle: .module) : String(localized: "Full Menu", bundle: .module))
          .font(.subheadline.weight(.semibold))
      }
    }
  }

  private var popularSection: RestaurantMenuSection {
    RestaurantMenuSection(
      id: "popular",
      title: String(localized: "Popular", bundle: .module),
      items: menu.popularItems.isEmpty ? Array(menu.sections.flatMap(\.items).prefix(3)) : menu.popularItems
    )
  }
}

struct RestaurantMenuItemRow: View {
  let item: RestaurantMenuItem
  var showsBadge: Bool = true

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 1) {
        HStack(spacing: 4) {
          Text(item.name)
            .font(.subheadline.weight(.medium))
          if showsBadge && item.isPopular {
            Image(systemName: "star.fill")
              .font(.caption2)
              .foregroundStyle(.orange)
              .accessibilityLabel(Text("Popular", bundle: .module))
          }
        }
        if let detail = item.detail {
          Text(detail)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
      Text(item.price.wonText)
        .font(.subheadline.monospacedDigit())
    }
  }
}
