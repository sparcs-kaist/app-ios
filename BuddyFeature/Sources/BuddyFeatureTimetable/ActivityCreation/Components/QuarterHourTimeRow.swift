//
//  QuarterHourTimeRow.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 10/9/26.
//

import SwiftUI

/// A `Form` row that shows a time and reveals an inline wheel when tapped.
///
/// The bound value is minutes since midnight, so 9:45 is 585. The wheel only
/// stops on quarter hours.
struct QuarterHourTimeRow: View {
	/// The granularity of the minute wheel.
	static let minuteStep = 15
	/// 23:45, the latest quarter hour of the day.
	static let lastMinuteOfDay = 23 * 60 + 45

	let title: String
	@Binding var minutes: Int
	@Binding var isExpanded: Bool

	init(_ title: String, minutes: Binding<Int>, isExpanded: Binding<Bool>) {
		self.title = title
		self._minutes = minutes
		self._isExpanded = isExpanded

		// The appearance proxy is read when the picker is created, so the
		// interval has to be set before this row's wheel appears.
		UIDatePicker.appearance().minuteInterval = Self.minuteStep
	}

	var body: some View {
		HStack {
			Text(title)

			Spacer()

			Button {
				withAnimation {
					isExpanded.toggle()
				}
			} label: {
				Text(Self.date(fromMinutes: minutes), format: .dateTime.hour().minute())
					.foregroundStyle(isExpanded ? Color.accentColor : .primary)
			}
			.buttonStyle(.bordered)
		}

		if isExpanded {
			DatePicker("", selection: selection, displayedComponents: [.hourAndMinute])
				.datePickerStyle(.wheel)
				.labelsHidden()
		}
	}

	/// Bridges the minutes value to the `Date` a `DatePicker` needs.
	private var selection: Binding<Date> {
		Binding {
			Self.date(fromMinutes: minutes)
		} set: { newValue in
			minutes = Self.minutes(from: newValue)
		}
	}

	private static func date(fromMinutes minutes: Int) -> Date {
		let calendar = Calendar.current
		let startOfDay = calendar.startOfDay(for: Date())
		return calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
	}

	/// Typed input can bypass the wheel's interval, so the value is snapped to
	/// the nearest quarter hour on the way in.
	private static func minutes(from date: Date) -> Int {
		let components = Calendar.current.dateComponents([.hour, .minute], from: date)
		let total = (components.hour ?? 0) * 60 + (components.minute ?? 0)
		let snapped = (Double(total) / Double(minuteStep)).rounded() * Double(minuteStep)
		return min(Int(snapped), lastMinuteOfDay)
	}
}

#Preview {
	@Previewable @State var begin = 9 * 60
	@Previewable @State var isExpanded = true

	Form {
		QuarterHourTimeRow("Starts", minutes: $begin, isExpanded: $isExpanded)
	}
}
