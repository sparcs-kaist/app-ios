//
//  LectureItem.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

public struct LectureItem: Identifiable {
  public let id = UUID()
  public let lecture: Lecture
  public let index: Int
}
