//
//  URL+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation

extension URL: @retroactive Identifiable {
  public var id: String { absoluteString }
}
