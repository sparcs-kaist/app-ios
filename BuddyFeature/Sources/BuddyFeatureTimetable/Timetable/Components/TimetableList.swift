//
//  LectureList.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 5/8/26.
//

import SwiftUI
import BuddyDomain

struct LectureList: View {
	let lectures: [Lecture]?
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("^[\(lectures?.count ?? 0) Lecture](inflect: true)")
				.font(.title3)
				.fontWeight(.bold)
			
			if let lectures, !lectures.isEmpty {
				ForEach(Array(lectures.enumerated()), id: \.element.id) { index, lecture in
					
					makeRow(lecture: lecture)
					
					if index != lectures.count - 1 {
						Divider()
							.padding(.leading, 20)
					}
				}
			} else {
				Text("There is no lecture for this timetable.")
					.frame(maxWidth: .infinity)
			}
		}
	}
	
	func makeRow(lecture: Lecture) -> some View {
		HStack(alignment: .center) {
			Circle()
				.frame(width: 12, height: 12)
				.foregroundStyle(lecture.backgroundColor)
			
			VStack(alignment: .leading) {
				Text(lecture.name)
					.font(.headline)
					.lineLimit(1)
				
				HStack {
					makeLabel(lecture.code, systemImage: "text.book.closed")
					makeLabel(lecture.professors.first?.name ?? "Unknown", systemImage: "person")
					makeLabel(lecture.classes.first?.location ?? "Unknown", systemImage: "mappin.and.ellipse")
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
	
	func makeLabel(_ text: String, systemImage: String) -> some View {
		HStack(alignment: .center, spacing: 4) {
			Image(systemName: systemImage)
			Text(text)
				.lineLimit(1)
		}
	}
	
	func creditLabel(credits: Int, label: String) -> some View {
		HStack(alignment: .bottom, spacing: 2) {
			Text("\(credits)")
				.fontDesign(.rounded)
				.font(.title3)
			
			Text(label)
				.font(.caption)
		}
	}
}


#Preview {
	LectureList(lectures: Lecture.mockList)
}
