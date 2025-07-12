//
//  WeekDaySelector.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import SwiftUI

struct WeekDaySelector: View {
  @Binding var selectedDate: Date
  let week: [Date]
  var select: ((Date) -> Void)?

  @Namespace private var selectionNamespace // 1. Create a Namespace

  private let calendar = Calendar.current

  var body: some View {
    HStack(spacing: 0) {
      ForEach(week, id: \.self) { day in
        let isSelected = calendar.isDate(selectedDate, inSameDayAs: day)
        let symbol = weekdaySymbol(for: day)
        let weekday = calendar.component(.weekday, from: day)

        let textColor: Color = {
          switch weekday {
          case 1:
            return .red
          case 7:
            return .blue
          default:
            return .primary
          }
        }()

        VStack(spacing: 4) {
          Text("\(calendar.component(.day, from: day))")
            .font(.title3)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .foregroundStyle(isSelected ? .white : .primary)

          Text(symbol)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(isSelected ? .white : textColor)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background {
          if isSelected {
            // 2. Apply matchedGeometryEffect to the selected background
            RoundedRectangle(cornerRadius: 24)
              .foregroundStyle(textColor)
              .matchedGeometryEffect(id: "selectedDay", in: selectionNamespace)
          }
        }
        .onTapGesture {
          withAnimation(.spring(duration: 0.35, bounce: 0.2, blendDuration: 0.15)) { // 3. Animate selection change
            selectedDate = day
            select?(day)
          }
        }
      }
    }
    .padding(4)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
  }

  private func weekdaySymbol(for date: Date) -> String {
    let weekdayIndex = calendar.component(.weekday, from: date) - 1
    return calendar.shortWeekdaySymbols[weekdayIndex].prefix(3).uppercased()
  }

  private func weekTitle(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM d"

    return formatter.string(from: date)
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
