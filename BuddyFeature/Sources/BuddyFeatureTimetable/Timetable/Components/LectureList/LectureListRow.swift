//
//  LectureListRow.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 5/9/26.
//

import SwiftUI
import BuddyDomain
import TimetableUI

struct LectureListRow: View {
	/// What the caption line under the name shows.
	enum Detail {
		/// Code, professor and location.
		case standard
		/// Code and lecture type, for grade entry, where the row shares its width with a grade button.
		case grading
	}

	let lecture: Lecture
	var detail: Detail = .standard
	@Environment(\.timetableTheme) private var theme

	var body: some View {
		HStack(alignment: .center) {
			Circle()
				.frame(width: 12, height: 12)
				.foregroundStyle(theme.color(forCourseID: lecture.courseID))
			
			VStack(alignment: .leading) {
				Text(lecture.name)
					.font(.headline)
					.lineLimit(1)
				
				HStack {
					makeLabel(lecture.code, systemImage: "text.book.closed")
					switch detail {
					case .standard:
						makeLabel(lecture.professors.first?.name ?? "Unknown", systemImage: "person")
						makeLabel(lecture.classes.first?.location ?? "Unknown", systemImage: "mappin.and.ellipse")
					case .grading:
						makeLabel(lecture.type.displayName.localized(), systemImage: "tag")
					}
				}
				.font(.caption)
				.foregroundStyle(.secondary)
			}
			
			Spacer()
			
			if lecture.credit > 0 {
				creditLabel(credits: lecture.credit, label: "CR")
			}
			
			if lecture.creditAU > 0 {
				creditLabel(credits: lecture.creditAU, label: "AU")
			}
		}
	}
	
	private func makeLabel(_ text: String, systemImage: String) -> some View {
		HStack(alignment: .center, spacing: 4) {
			Image(systemName: systemImage)
			Text(text)
				.lineLimit(1)
		}
	}
	
	private func creditLabel(credits: Int, label: String) -> some View {
		HStack(alignment: .bottom, spacing: 2) {
			Text("\(credits)")
				.fontDesign(.rounded)
				.font(.title3)
			
			Text(label)
				.font(.caption)
				.offset(y: -1)
		}
	}
}

#Preview {
	VStack(alignment: .leading, spacing: 16) {
		ForEach(Lecture.mockList.prefix(3)) { lecture in
			LectureListRow(lecture: lecture)
			// Grade entry: a 44pt grade button sits beside the row.
			HStack {
				LectureListRow(lecture: lecture, detail: .grading)
				Capsule().fill(.orange.opacity(0.15)).frame(width: 44, height: 32)
			}
			Divider()
		}
	}
	.padding()
}
