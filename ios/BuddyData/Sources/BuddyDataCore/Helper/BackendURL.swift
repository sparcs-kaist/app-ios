//
//  BackendURL.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation
import BuddyDomain

public enum BackendURL {
  // MARK: Authorisation
  public static let authorisationURL: URL? = {
    if Status.isProduction {
      return URL(string: "https://taxi.sparcs.org/api/auth/sparcsapp/login")
    } else {
      return URL(string: "https://taxi.dev.sparcs.org/api/auth/sparcsapp/login")
    }
  }()

  // MARK: Taxi
  public static let taxiBackendURL = {
    if Status.isProduction {
      return URL(string: "https://taxi.sparcs.org/api")!
    } else {
      return URL(string: "https://taxi.dev.sparcs.org/api")!
    }
  }()

  public static let taxiSocketURL = {
    if Status.isProduction {
      return URL(string: "https://taxi.sparcs.org/")!
    } else {
      return URL(string: "https://taxi.dev.sparcs.org/")!
    }
  }()


  // MARK: Ara
  public static let araBackendURL = {
    if Status.isProduction {
      return URL(string: "https://newara.sparcs.org/api")!
    } else {
      return URL(string: "https://newara.dev.sparcs.org/api")!
    }
  }()

  // MARK: Feed
  public static let feedBackendURL = {
    if Status.isProduction {
      return URL(string: "https://buddy.sparcs.org/v1")!
    } else {
      return URL(string: "https://buddy.dev.sparcs.org/v1")!
    }
  }()

  // MARK: OTL
  public static let otlBackendURL = {
    if Status.isProduction {
      return URL(string: "https://otl.sparcs.org")!
    } else {
      return URL(string: "https://api.otl.dev.sparcs.org")!
    }
  }()
}
