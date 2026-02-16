//
//  MessagePresentationPolicy.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 15/02/2026.
//

import Foundation
import BuddyDomain

protocol MessagePresentationPolicy {
  func metadata(
    kind: TaxiChat.ChatType,
    isMine: Bool,
    indexInCluster: Int,
    clusterCount: Int,
    isStandalone: Bool
  ) -> MetadataVisibility
}

struct DefaultMessagePresentationPolicy: MessagePresentationPolicy {
  func metadata(
    kind: TaxiChat.ChatType,
    isMine: Bool,
    indexInCluster: Int,
    clusterCount: Int,
    isStandalone: Bool
  ) -> MetadataVisibility {
    if isStandalone {
      return MetadataVisibility(
        showName: !isMine,
        showAvatar: !isMine,
        showTime: true
      )
    }

    let isFirst = indexInCluster == 0
    let isLast = indexInCluster == clusterCount - 1

    if isMine {
      return MetadataVisibility(showName: false, showAvatar: false, showTime: isLast)
    } else {
      return MetadataVisibility(showName: isFirst, showAvatar: isLast, showTime: isLast)
    }
  }
}
