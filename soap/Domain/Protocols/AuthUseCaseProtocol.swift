//
//  AuthUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Combine

protocol AuthUseCaseProtocol {
  var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
  func signIn() async throws
  func signOut() async throws
  func getAccessToken() -> String?
  func refreshAccessTokenIfNeeded() async throws
}
