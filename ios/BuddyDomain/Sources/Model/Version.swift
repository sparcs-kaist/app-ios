//
//  Version.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 10/06/2026.
//

import Foundation

/// A lightweight semantic version value type.
///
/// Provides the small subset of functionality the app needs (parsing,
/// comparison and a string description) so we don't depend on an external
/// versioning package.
public struct Version: Comparable, Hashable, Sendable, CustomStringConvertible {
  public let major: Int
  public let minor: Int
  public let patch: Int

  /// The zero version (`0.0.0`).
  public static let null = Version(major: 0, minor: 0, patch: 0)

  public init(major: Int, minor: Int, patch: Int = 0) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }

  /// Parses a dot-separated version string such as `"1.2.3"`, `"1.2"`, or `"3"`.
  ///
  /// Any pre-release or build metadata (everything after a `-` or `+`) is
  /// ignored. Missing components default to zero. Returns `nil` if a present
  /// component is not a non-negative integer or there are more than three.
  public init?(_ string: String) {
    let core = string.prefix { $0 != "-" && $0 != "+" }
    let components = core.split(separator: ".", omittingEmptySubsequences: false)
    guard !components.isEmpty, components.count <= 3 else { return nil }

    var values = [0, 0, 0]
    for (index, component) in components.enumerated() {
      guard let value = Int(component), value >= 0 else { return nil }
      values[index] = value
    }
    self.init(major: values[0], minor: values[1], patch: values[2])
  }

  public var description: String {
    "\(major).\(minor).\(patch)"
  }

  public static func < (lhs: Version, rhs: Version) -> Bool {
    (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
  }
}

public extension Bundle {
  /// The bundle's short version string (`CFBundleShortVersionString`) parsed as a ``Version``.
  ///
  /// Returns ``Version/null`` when the value is absent or unparseable.
  var version: Version {
    (infoDictionary?["CFBundleShortVersionString"] as? String).flatMap(Version.init) ?? .null
  }
}
