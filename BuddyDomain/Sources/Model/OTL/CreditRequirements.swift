//
//  CreditRequirements.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import Foundation

/// Minimum credits required to graduate, per requirement type.
///
/// Requirements differ by department and admission year, so these are defaults
/// the user can edit to match their own. Taken credits may exceed any minimum.
public struct CreditRequirements: Codable, Equatable, Sendable {
  public static let defaultMajorRequired = 19
  public static let defaultMajorElective = 24

  public var graduation = 138
  public var basicRequired = 23
  public var basicElective = 9
  public var hseCore = 3
  public var hseGeneral = 18
  public var au = 4
  /// Per-department overrides, keyed by department ID; missing ones use the defaults.
  public var majorRequired: [Int: Int] = [:]
  public var majorElective: [Int: Int] = [:]

  public init() {}

  // Missing keys fall back to defaults, so fields added later don't discard saved edits.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = CreditRequirements()
    graduation = try container.decodeIfPresent(Int.self, forKey: .graduation) ?? defaults.graduation
    basicRequired = try container.decodeIfPresent(Int.self, forKey: .basicRequired) ?? defaults.basicRequired
    basicElective = try container.decodeIfPresent(Int.self, forKey: .basicElective) ?? defaults.basicElective
    hseCore = try container.decodeIfPresent(Int.self, forKey: .hseCore) ?? defaults.hseCore
    hseGeneral = try container.decodeIfPresent(Int.self, forKey: .hseGeneral) ?? defaults.hseGeneral
    au = try container.decodeIfPresent(Int.self, forKey: .au) ?? defaults.au
    majorRequired = try container.decodeIfPresent([Int: Int].self, forKey: .majorRequired) ?? [:]
    majorElective = try container.decodeIfPresent([Int: Int].self, forKey: .majorElective) ?? [:]
  }

  public func majorRequired(for department: Department) -> Int {
    majorRequired[department.id] ?? Self.defaultMajorRequired
  }

  public func majorElective(for department: Department) -> Int {
    majorElective[department.id] ?? Self.defaultMajorElective
  }
}

/// Saves each user's edited credit requirements on this device.
public struct CreditRequirementsStore {
  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

  private static func key(userID: Int) -> String { "creditRequirements.\(userID)" }

  /// The user's saved requirements, or the defaults if they never edited them.
  public func requirements(userID: Int) -> CreditRequirements {
    guard let data = defaults.data(forKey: Self.key(userID: userID)),
          let requirements = try? JSONDecoder().decode(CreditRequirements.self, from: data)
    else { return CreditRequirements() }
    return requirements
  }

  public func save(_ requirements: CreditRequirements, userID: Int) {
    guard let data = try? JSONEncoder().encode(requirements) else { return }
    defaults.set(data, forKey: Self.key(userID: userID))
  }
}
