//
//  APIErrorResponse.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import Foundation

struct APIErrorResponse: Decodable, Error, LocalizedError {
  let error: String

  var errorDescription: String? {
    return error
  }
}
