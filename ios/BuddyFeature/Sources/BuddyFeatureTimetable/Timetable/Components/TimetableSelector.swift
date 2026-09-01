//
//  TimetableSelector.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

//import SwiftUI
//
//struct TimetableSelector: View {
//  @Environment(TimetableViewModel.self) private var timetableViewModel
//
//  var body: some View {
//    ZStack {
//      if let selectedTimetable = timetableViewModel.selectedTimetable {
//        HStack {
//          HStack {
//            Button(action: {
//              timetableViewModel.selectPreviousSemester()
//            }, label: {
//              Image(systemName: "chevron.left")
//            })
//            .tint(.black)
//            .disabled(timetableViewModel.semesters.first == selectedTimetable.semester)
//
//            Spacer()
//
//            Text(selectedTimetable.semester.description)
//
//            Spacer()
//
//            Button(action: {
//              timetableViewModel.selectNextSemester()
//            }, label: {
//              Image(systemName: "chevron.right")
//            })
//            .tint(.black)
//            .disabled(timetableViewModel.semesters.last == selectedTimetable.semester)
//          }
//          .frame(maxWidth: 160)
//          .fontWeight(.semibold)
//
//          ScrollView(.horizontal, showsIndicators: false) {
//            LazyHStack {
//              ForEach(timetableViewModel.timetablesForSelectedSemester.indices, id: \.self) { index in
//                let isSelected: Bool = timetableViewModel.timetablesForSelectedSemester[index] == selectedTimetable
//                HStack {
//                  Text(index == 0 ? "My Table" : "Table \(index)")
//                  if isSelected {
//                    Button(action: {
//
//                    }, label: {
//                      Image(systemName: "ellipsis")
//                    })
//                  }
//                }
//                .font(.callout)
//                .foregroundStyle(isSelected ? .white : .black)
//                .padding(8)
//                .padding(.horizontal, 4)
//                .background(
//                  Capsule()
//                    .fill(isSelected ? .accent : .white)
//                )
//              }
//            }
//            .padding(.trailing)
//            .scrollTargetLayout()
//          }
//          .scrollTargetBehavior(.viewAligned)
//        }
//      }
//    }
//    .frame(height: 40)
//    .task {
//      await timetableViewModel.fetchData()
//    }
//  }
//}
//
//#Preview {
//  TimetableSelector()
//    .environment(TimetableViewModel())
//    .background(
//      Color(UIColor.secondarySystemBackground)
//    )
//}
//
