//
//  ErrorSource.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/02/2026.
//


public enum ErrorSource: String, Sendable {
  case network
  case repository
  case useCase
  case domain
  case unknown
}
