//
//  TaxiParticipant.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

struct TaxiParticipant: Identifiable, Hashable {
  let id: String
  let name: String
  let nickname: String
  let profileImageURL: URL?
  let withdraw: Bool
  let readAt: Date
}
