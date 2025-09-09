//
//  FeedPostPage.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation

struct FeedPostPage {
  let items: [FeedPost]
  let nextCursor: String?
  let hasNext: Bool
}

