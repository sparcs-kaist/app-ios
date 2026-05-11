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
	var selectedLecture: ((LectureItem) -> Void)?
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("\(lectures?.count ?? 0) Lectures", bundle: .module)
				.font(.title3)
				.fontWeight(.bold)
			
			if let lectures, !lectures.isEmpty {
				ForEach(Array(lectures.enumerated()), id: \.element.id) { index, lecture in
					
					LectureListRow(lecture: lecture)
						.contentShape(.rect)
						.onTapGesture {
							guard let lectureClass = lecture.classes.first else { return }
							let item = LectureItem(lecture: lecture, lectureClass: lectureClass)
							selectedLecture?(item)
						}
					
					if index != lectures.count - 1 {
						Divider()
							.padding(.leading, 20)
					}
				}
			} else {
				Text("There is no lecture for this timetable.", bundle: .module)
					.padding()
					.frame(maxWidth: .infinity)
			}
		}
	}
}


#Preview {
	LectureList(lectures: Lecture.mockList, selectedLecture: nil)
}
