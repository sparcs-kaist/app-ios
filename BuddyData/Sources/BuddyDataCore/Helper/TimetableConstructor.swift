//
//  TimetableConstructor.swift
//  soap
//
//  Created by Soongyu Kwon on 29/12/2024.
//

import UIKit
import BuddyDomain

public struct TimetableConstructor {
  // The width of the column representing the time at the leftmost of the timetable
  public static let hoursWidth: CGFloat = 16

  // The height of the row representing the day at the top of the timetable
  public static let daysHeight: CGFloat = 16

  /*
   * getCellHeight: Calculate the height of the lecture cell based on size of the timetable and its status
   * for: LectureItem
   * in: CGSize - size of the timetable(GeometryReader)
   * of: Int - duration of the timetable
   */
  public static func getCellHeight(for item: LectureItem, in size: CGSize, of duration: Int) -> CGFloat {
    let timetableHeight: CGFloat = size.height - daysHeight - 14
    let cellHeight: CGFloat = (timetableHeight / CGFloat(duration)) * CGFloat(item.lecture.classTimes[item.index].duration)

    return (cellHeight <= 0) ? 0 : cellHeight - 4
  }

  public static func getCellOffset(for item: LectureItem, in size: CGSize, at start: Int, of duration: Int) -> CGFloat {
    let timetableHeight: CGFloat = size.height - daysHeight - 14
    let difference: CGFloat = (timetableHeight / CGFloat(duration)) * CGFloat(item.lecture.classTimes[item.index].begin - start)
    return daysHeight + 14 + difference
  }
}

