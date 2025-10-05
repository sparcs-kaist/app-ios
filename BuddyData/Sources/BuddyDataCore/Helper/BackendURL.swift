//
//  BackendURL.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public enum BackendURL {
  // MARK: Authorisation
  public static let authorisationURL: URL? = {
    #if DEBUG
    return URL(string: "https://taxi.dev.sparcs.org/api/auth/sparcsapp/login")
    #else
    return URL(string: "https://taxi.sparcs.org/api/auth/sparcsapp/login")
    #endif
  }()

  // MARK: Taxi
  public static let taxiBackendURL = {
    #if DEBUG
    return URL(string: "https://taxi.dev.sparcs.org/api")!
    #else
    return URL(string: "https://taxi.sparcs.org/api")!
    #endif
  }()

  public static let taxiSocketURL = {
    #if DEBUG
    return URL(string: "https://taxi.dev.sparcs.org/")!
    #else
    return URL(string: "https://taxi.sparcs.org/")!
    #endif
  }()


  // MARK: Ara
  public static let araBackendURL = {
    #if DEBUG
    return URL(string: "https://newara.dev.sparcs.org/api")!
    #else
    return URL(string: "https://newara.sparcs.org/api")!
    #endif
  }()

  // MARK: Feed
  public static let feedBackendURL = {
    #if DEBUG
    return URL(string: "https://app.dev.sparcs.org/v1")!
    #else
    return URL(string: "https://buddy.sparcs.org/v1")!
    #endif
  }()

  // MARK: OTL
  public static let otlBackendURL = {
    #if DEBUG
    return URL(string: "https://api.otl.dev.sparcs.org")!
    #else
    return URL(string: "https://otl.sparcs.org")!
    #endif
  }()
}
