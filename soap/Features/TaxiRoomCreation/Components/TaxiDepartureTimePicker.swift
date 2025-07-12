//
//  TaxiDepartureTimePicker.swift
//  soap
//
//  Created by 김민찬 on 3/23/25.
//

import SwiftUI

struct TaxiDepartureTimePicker: View {
  @Binding var departureTime: Date

  @State private var showDatePicker = false
  @State private var showTimePicker = false

  init(departureTime: Binding<Date>) {
    self._departureTime = departureTime

    UIDatePicker.appearance().minuteInterval = 10
  }

  var body: some View {
    HStack {
      Text("Departure Time")

      Spacer()

      Button {
        withAnimation {
          showDatePicker.toggle()
          showTimePicker = false
        }
      } label: {
        Text(departureTime.formatted(.dateTime.month().day()))
          .foregroundStyle(showDatePicker ? .accent : .primary)
      }
      .buttonStyle(.bordered)
      Button {
        withAnimation {
          showTimePicker.toggle()
          showDatePicker = false
        }
      } label: {
        Text(departureTime.formatted(.dateTime.hour().minute()))
          .foregroundStyle(showTimePicker ? .accent : .primary)
      }
      .buttonStyle(.bordered)
    }

    if showDatePicker {
      DatePicker("",
                 selection: $departureTime,
                 in: getDateRange(),
                 displayedComponents: [.date]
      )
      .datePickerStyle(.graphical)
    }

    if showTimePicker {
      DatePicker("",
                 selection: $departureTime,
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
  TaxiDepartureTimePicker(departureTime: .constant(Date().ceilToNextTenMinutes()))
}
