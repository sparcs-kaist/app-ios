//
//  ActivityCreationView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 9/9/26.
//

import SwiftUI
import BuddyDomain

//enum CreationMode: String, CaseIterable, Identifiable {
//	case manual = "Enter Manually"
//	case fromTimetable = "Select from Timetable"
//	
//	var id: String { rawValue }
//}

struct ActivityCreationView: View {
	/// The time row whose wheel is currently showing, if any.
	private enum TimeField {
		case begin
		case end
	}

//	@State private var creationMode: CreationMode = .manual
	@State private var title: String = ""
	@State private var location: String = ""
	@State private var day: DayType = .today
	/// Minutes since midnight, so 9:45 is 585.
	@State private var begin: Int = 9 * 60
	@State private var end: Int = 10 * 60
	@State private var expandedField: TimeField?
	
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			Form {
				Section {
					TextField("Title", text: $title, prompt: Text("Title"))
					TextField("Location", text: $location, prompt: Text("Location"))
				}
				
				Section(String(localized: "Date", bundle: .module)) {
					Picker("Day", selection: $day) {
						ForEach(DayType.allCases) { day in
							Text(day.stringValue)
								.tag(day)
						}
					}

					QuarterHourTimeRow(
						String(localized: "Starts", bundle: .module),
						minutes: $begin,
						isExpanded: isExpanded(.begin)
					)

					QuarterHourTimeRow(
						String(localized: "Ends", bundle: .module),
						minutes: $end,
						isExpanded: isExpanded(.end)
					)
				}
				.onChange(of: begin) { oldValue, newValue in
					// Moving the start time keeps the duration, like Calendar does.
					let duration = max(QuarterHourTimeRow.minuteStep, end - oldValue)
					end = min(newValue + duration, QuarterHourTimeRow.lastMinuteOfDay)
				}
				.onChange(of: end) { _, newValue in
					// The end can never reach back past the start.
					if newValue <= begin {
						end = min(
							begin + QuarterHourTimeRow.minuteStep,
							QuarterHourTimeRow.lastMinuteOfDay
						)
					}
				}
			}
			.navigationTitle(Text("New Activity"))
			.navigationSubtitle(Text("Add to \"Timetable 1\""))
			.navigationBarTitleDisplayMode(.inline)
			.scrollEdgeEffectStyle(.soft, for: .top)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button("Close", systemImage: "xmark", role: .cancel) {
						dismiss()
					}
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button("Add", systemImage: "plus", role: .confirm) {
						
					}
				}
			}
		}
	}

	/// Only one wheel shows at a time, so expanding a row collapses the other.
	private func isExpanded(_ field: TimeField) -> Binding<Bool> {
		Binding {
			expandedField == field
		} set: { newValue in
			expandedField = newValue ? field : nil
		}
	}
}

struct ActivityManualCreationView: View {
	var body: some View {
		VStack {
			
		}
	}
}

struct ActivityTimetableCreationView: View {
	var body: some View {
		VStack {
			
		}
	}
}

#Preview {
	ActivityCreationView()
}
