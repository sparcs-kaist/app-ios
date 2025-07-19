//
//  LectureItem.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

struct LectureItem: Identifiable {
  let id = UUID()
  let lecture: Lecture
  let index: Int
}
