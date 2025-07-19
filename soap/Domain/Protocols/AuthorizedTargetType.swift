//
//  AuthorizedTargetType.swift
//  soap
//
//  Created by Soongyu Kwon on 10/07/2025.
//

import Foundation
import Moya

protocol AuthorizedTargetType: TargetType {
  var needsAuth: Bool { get }
}
