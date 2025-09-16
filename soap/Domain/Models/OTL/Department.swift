//
//  Department.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation

struct Department: Identifiable, Hashable {
  let id: Int
  let name: LocalizedString
  let code: String
}
