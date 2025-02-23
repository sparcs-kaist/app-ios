//
//  PostListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI
import Observation

@Observable
class PostListViewModel {
  var postList: [Post] = Post.mockList
  var flairList: [String] = [
    "SPPANGS",
    "Meal",
    "Money",
    "Gaming",
    "Dating",
    "Lost & Found",
  ]
}
