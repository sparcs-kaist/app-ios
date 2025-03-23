//
//  TaxiDepatureTimePicker.swift
//  soap
//
//  Created by 김민찬 on 3/23/25.
//

import SwiftUI

struct TaxiDepatureTimePicker: View {
  @Binding var depatureTime: Date

  @State private var showDatePicker = false // TODO: ViewModel required?
  @State private var showTimePicker = false

  var body: some View {
    HStack {
      Text("Depature Time")

      Spacer()

      Button {
        withAnimation {
          showDatePicker.toggle()
          showTimePicker = false
        }
      } label: {
        Text(depatureTime.formatted(.dateTime.month().day()))
          .foregroundStyle(showDatePicker ? .accent : .primary)
      }
      .buttonStyle(.bordered)
      Button {
        withAnimation {
          showTimePicker.toggle()
          showDatePicker = false
        }
      } label: {
        Text(depatureTime.formatted(.dateTime.hour().minute()))
          .foregroundStyle(showTimePicker ? .accent : .primary)
      }
      .buttonStyle(.bordered)
    }

    if showDatePicker {
      DatePicker("",
                 selection: $depatureTime,
                 in: getDateRange(),
                 displayedComponents: [.date]
      )
      .datePickerStyle(.graphical)
    }

    if showTimePicker {
      DatePicker("",
                 selection: $depatureTime,
                 in: getDateRange(),
                 displayedComponents: [.hourAndMinute]
      )
      .datePickerStyle(.wheel)
    }
  }

  private func getDateRange() -> ClosedRange<Date> {
    let calander = Calendar.current
    let now = Date()
    let thirteenDaysLater = calander.date(byAdding: .day, value: 13, to: now)!
    return now...calander.date(bySettingHour: 23, minute: 59, second: 59, of: thirteenDaysLater)!
  }
}

#Preview {
  TaxiDepatureTimePicker(depatureTime: .constant(Date().ceilToNextTenMinutes()))
}

