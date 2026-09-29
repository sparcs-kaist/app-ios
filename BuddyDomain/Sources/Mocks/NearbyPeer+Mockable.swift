//
//  NearbyPeer+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation

extension NearbyPeer: Mockable { }

public extension NearbyPeer {
  static var mock: NearbyPeer {
    NearbyPeer(id: "a1b2c3d4e5f6a1b2c3d4e5f6", name: "김수진")
  }

  static var mockList: [NearbyPeer] {
    [
      NearbyPeer(id: "a1b2c3d4e5f6a1b2c3d4e5f6", name: "김수진"),
      NearbyPeer(id: "0f1e2d3c4b5a0f1e2d3c4b5a", name: "Minho Lee"),
      NearbyPeer(id: "9a8b7c6d5e4f9a8b7c6d5e4f", name: "박지우"),
      NearbyPeer(id: "1234567890ab1234567890ab", name: "Haeun Choi"),
      NearbyPeer(id: "abcdefabcdefabcdefabcdef", name: "정도윤")
    ]
  }
}
