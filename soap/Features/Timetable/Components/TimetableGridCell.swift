//
//  TimetableGridCell.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI

struct TimetableGridCell: View {
    let lecture: Lecture
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(lecture.backgroundColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lecture.title)
                        .font(.caption)
                        .lineLimit(3)
                    Text(lecture.classTimes[0].classroomNameShort)
                        .font(.caption2)
                        .opacity(0.8)
                }
                .foregroundStyle(lecture.textColor)
                .padding(6)
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 88, height: 105)) {
    TimetableGridCell(lecture: Lecture.mockList[0])
}

#Preview(traits: .fixedLayout(width: 88, height: 105)) {
    TimetableGridCell(lecture: Lecture.mockList[1])
}

#Preview(traits: .fixedLayout(width: 88, height: 105)) {
    TimetableGridCell(lecture: Lecture.mockList[2])
}

#Preview(traits: .fixedLayout(width: 88, height: 105)) {
    TimetableGridCell(lecture: Lecture.mockList[3])
}
