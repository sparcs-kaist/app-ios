//
//  SourcedError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/02/2026.
//


public protocol SourcedError: Error {
  var source: ErrorSource { get }
}
