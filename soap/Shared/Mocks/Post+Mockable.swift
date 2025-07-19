//
//  Post+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import Foundation

#if DEBUG
extension Post: Mockable {
  static var mock: Post {
    Post(
      title: "some title",
      description: "verrrry loooonnngggg description",
      voteCount: 10,
      commentCount: 20,
      author: "Anonymous",
      createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
      thumbnailURL: nil
    )
  }

  static var mockList: [Post] {
    [
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 10,
        commentCount: 20,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg asdfojapsdofpoweufpoqiewfpoqiuwepfoiquwepfoiquwepfoiqwuepfoiqwuepfoiquwepfoiquwepofiquwepofiuqpwoeifuqpwoeifuqpwoeifu",
        voteCount: -100,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        thumbnailURL: URL(string: "https://newara.sparcs.org")
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 122,
        commentCount: 1,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .second, value: -30, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 10,
        commentCount: 20,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg asdfojapsdofpoweufpoqiewfpoqiuwepfoiquwepfoiquwepfoiqwuepfoiqwuepfoiquwepfoiquwepofiquwepofiuqpwoeifuqpwoeifuqpwoeifu",
        voteCount: -100,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        thumbnailURL: URL(string: "https://newara.sparcs.org")
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 122,
        commentCount: 1,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .second, value: -30, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 10,
        commentCount: 20,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg asdfojapsdofpoweufpoqiewfpoqiuwepfoiquwepfoiquwepfoiqwuepfoiqwuepfoiquwepfoiquwepofiquwepofiuqpwoeifuqpwoeifuqpwoeifu",
        voteCount: -100,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        thumbnailURL: URL(string: "https://newara.sparcs.org")
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 122,
        commentCount: 1,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .second, value: -30, to: Date())!,
        thumbnailURL: nil
      ),
      Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        thumbnailURL: nil
      ),
    ]
  }
}
#endif
