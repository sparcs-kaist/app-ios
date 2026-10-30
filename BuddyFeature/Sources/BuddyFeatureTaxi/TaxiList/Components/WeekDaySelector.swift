//
//  WeekDaySelector.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import Foundation
import SwiftUI

struct WeekDaySelector: View {
  @Binding var selectedDate: Date
  let week: [Date]
  var select: ((Date) -> Void)?

  @Environment(\.colorScheme) private var colorScheme

  private let calendar = Calendar.current

  var body: some View {
    // Tap a day, or swipe along the week to drag the glass lens to one.
    LiquidLensSegments(
      count: week.count,
      selectedIndex: week.firstIndex { calendar.isDate(selectedDate, inSameDayAs: $0) } ?? 0,
      selectionColors: week.map(selectionColor),
      cornerRadius: 24,
      onSelect: { index in
        withAnimation(.spring(duration: 0.35, bounce: 0.2, blendDuration: 0.15)) {
          selectedDate = week[index]
          select?(week[index])
        }
      }
    ) { index, isSelected in
      dayLabel(for: week[index], isSelected: isSelected)
    }
    .padding(4)
    .contentShape(.rect(cornerRadius: 28))
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
  }

  private func dayLabel(for day: Date, isSelected: Bool) -> some View {
    VStack(spacing: 4) {
      Text("\(calendar.component(.day, from: day))")
        .font(.title3)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .foregroundStyle(isSelected ? selectedTextColor(for: day) : .primary)

      Text(weekdaySymbol(for: day))
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundStyle(isSelected ? selectedTextColor(for: day) : textColor(for: day))
    }
    .frame(minHeight: 60)
  }

  private func textColor(for day: Date) -> Color {
    switch calendar.component(.weekday, from: day) {
    case 1:
      return .red
    case 7:
      return .blue
    default:
      return .primary
    }
  }

  private func isWeekend(_ day: Date) -> Bool {
    let weekday = calendar.component(.weekday, from: day)
    return weekday == 1 || weekday == 7
  }

  // Solid colours for the selected day rather than `.primary`: on the selector's glass that turns
  // translucent and the pill shows grey. A weekday's pill is black, or white in dark mode with dark
  // text on it; weekends keep their red and blue.
  private func selectionColor(for day: Date) -> Color {
    isWeekend(day) ? textColor(for: day) : (colorScheme == .dark ? .white : .black)
  }

  private func selectedTextColor(for day: Date) -> Color {
    !isWeekend(day) && colorScheme == .dark ? .black : .white
  }

  private func weekdaySymbol(for date: Date) -> String {
    let weekdayIndex = calendar.component(.weekday, from: date) - 1
    return calendar.shortWeekdaySymbols[weekdayIndex].prefix(3).uppercased()
  }
}

#Preview {
  @Previewable @State var date: Date = Date()
  var week: [Date] {
    let calendar = Calendar.current
    return (0..<7).compactMap {
      calendar.date(byAdding: .day, value: $0, to: Date())
    }
  }

  ZStack {
    Color.secondarySystemBackground
    WeekDaySelector(selectedDate: $date, week: week)
      .padding()
  }
  .ignoresSafeArea()
}
