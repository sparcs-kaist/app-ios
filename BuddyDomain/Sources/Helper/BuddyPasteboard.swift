//
//  BuddyPasteboard.swift
//  BuddyDomain
//
//  UIPasteboard/NSPasteboard differ in both name and shape, so callers go through
//  this instead of branching at every copy site.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum BuddyPasteboard {
  public static func copy(_ string: String) {
    #if os(iOS)
    UIPasteboard.general.string = string
    #elseif os(macOS)
    // NSPasteboard keeps previous contents until explicitly cleared.
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
    #endif
  }
}
