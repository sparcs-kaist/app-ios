//
//  AraPostAuthorProfile.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

struct AraPostAuthorProfile: Identifiable, Hashable {
  let id: Int
  let profilePictureURL: URL?
  let nickname: String
  let isOfficial: Bool
  let isSchoolAdmin: Bool
}
