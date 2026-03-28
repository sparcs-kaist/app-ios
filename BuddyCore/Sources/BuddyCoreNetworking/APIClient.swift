//
//  APIClient.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation

protocol APIClient: Sendable {
  func request<T: Decodable & Sendable>(
    _ endpoint: Endpoint,
    as type: T.Type
  ) async throws -> T
}
