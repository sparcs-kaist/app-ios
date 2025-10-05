//
//  APIErrorResponse.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import Foundation

public struct APIErrorResponse: Decodable, Error, LocalizedError {
  let error: String

  public var errorDescription: String? {
    return error
  }
}
