//
//  AraUserRepositoryProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation

protocol AraUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws
}
