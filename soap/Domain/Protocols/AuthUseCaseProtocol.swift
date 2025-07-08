//
//  AuthUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

protocol AuthUseCaseProtocol {
  func signIn() async throws
  func signOut() async throws
}
