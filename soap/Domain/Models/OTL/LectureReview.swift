//
//  LectureReview.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

struct LectureReview: Identifiable {
  let id: Int
  let course: Course
  let lecture: Lecture
  let content: String
  let like: Int
  let grade: Int
  let load: Int
  let speech: Int
  let isLiked: Bool
}
