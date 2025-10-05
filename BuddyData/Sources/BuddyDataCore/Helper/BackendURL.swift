//
//  BackendURL.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public enum BackendURL {
  // MARK: Authorisation
  public static let authorisationURL = URL(string: "https://taxi.dev.sparcs.org/api/auth/sparcsapp/login")

  // MARK: Terms
  public static let privacyPolicyURL = URL(string: "https://github.com/sparcs-kaist/privacy/blob/main/Privacy.md")!
  public static let termsOfUseURL = URL(string: "https://github.com/sparcs-kaist/privacy/blob/main/TermsOfUse.md")!

  // MARK: Taxi
  public static let taxiBackendURL = URL(string: "https://taxi.dev.sparcs.org/api")!
  public static let taxiSocketURL = URL(string: "https://taxi.dev.sparcs.org/")!

  // MARK: Ara
  public static let araBackendURL = URL(string: "https://newara.dev.sparcs.org/api")!

  // MARK: Feed
  public static let feedBackendURL = URL(string: "https://app.dev.sparcs.org/v1")!

  // MARK: OTL
  public static let otlBackendURL = URL(string: "https://api.otl.dev.sparcs.org")!
}
