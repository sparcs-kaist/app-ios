//
//  LectureListRow.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 5/9/26.
//

import SwiftUI
import BuddyDomain

struct LectureListRow: View {
	let lecture: Lecture
	
	var body: some View {
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
