//
//  AraPostComment+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

extension AraPostComment: Mockable {
  static var mock: AraPostComment {
    AraPostComment(
      id: 1542,
      isHidden: false,
      hiddenReason: [],
      overrideHidden: nil,
      myVote: nil,
      isMine: false,
      content: "헉 어떡해@!",
      author: AraPostAuthor(
        id: "749",
        username: "c312e26e-7a6b-405d-9e13-84c058325567",
        profile: AraPostAuthorProfile(
          id: "749",
          profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/scaled_1000003865.png"),
          nickname: "일반사용자",
          isOfficial: false,
          isSchoolAdmin: false
        ),
        isBlocked: false
      ),
      comments: [
        AraPostComment(
          id: 1550,
          isHidden: false,
          hiddenReason: [],
          overrideHidden: nil,
          myVote: nil,
          isMine: false,
          content: "어머",
          author: AraPostAuthor(
            id: "984",
            username: "c7431c7c-adfa-44e5-8045-306535494ea1",
            profile: AraPostAuthorProfile(
              id: "984",
              profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/default_pictures/blue-default1.png"),
              nickname: "신나는 포도",
              isOfficial: false,
              isSchoolAdmin: false
            ),
            isBlocked: false
          ),
          comments: [],
          createdAt: Date(timeIntervalSince1970: 1699887315.272441),
          upvotes: 0,
          downvotes: 0,
          parentPost: 6176,
          parentComment: 1542
        )
      ],
      createdAt: Date(timeIntervalSince1970: 1699041372.803443),
      upvotes: 0,
      downvotes: 0,
      parentPost: 6176,
      parentComment: nil
    )
  }

  static var mockList: [AraPostComment] {
    [
      AraPostComment(
        id: 1542,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        myVote: nil,
        isMine: false,
        content: "헉 어떡해@!",
        author: AraPostAuthor(
          id: "749",
          username: "c312e26e-7a6b-405d-9e13-84c058325567",
          profile: AraPostAuthorProfile(
            id: "749",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/scaled_1000003865.png"),
            nickname: "일반사용자ㅏ",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        comments: [
          AraPostComment(
            id: 1550,
            isHidden: false,
            hiddenReason: [],
            overrideHidden: nil,
            myVote: nil,
            isMine: false,
            content: "어머",
            author: AraPostAuthor(
              id: "984",
              username: "c7431c7c-adfa-44e5-8045-306535494ea1",
              profile: AraPostAuthorProfile(
                id: "984",
                profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/default_pictures/blue-default1.png"),
                nickname: "신나는 포도",
                isOfficial: false,
                isSchoolAdmin: false
              ),
              isBlocked: false
            ),
            comments: [],
            createdAt: Date(timeIntervalSince1970: 1699887315.272441),
            upvotes: 0,
            downvotes: 0,
            parentPost: 6176,
            parentComment: 1542
          )
        ],
        createdAt: Date(timeIntervalSince1970: 1699041372.803443),
        upvotes: 0,
        downvotes: 0,
        parentPost: 6176,
        parentComment: nil
      ),
      AraPostComment(
        id: 1543,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        myVote: nil,
        isMine: false,
        content: "허걱",
        author: AraPostAuthor(
          id: "980",
          username: "roul",
          profile: AraPostAuthorProfile(
            id: "980",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/111356146_p0_q4rKgeN.jpg"),
            nickname: "롸?",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        comments: [],
        createdAt: Date(timeIntervalSince1970: 1699382798.345518),
        upvotes: 0,
        downvotes: 0,
        parentPost: 6176,
        parentComment: nil
      ),
      AraPostComment(
        id: 1544,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        myVote: nil,
        isMine: false,
        content: "앗",
        author: AraPostAuthor(
          id: "982",
          username: "859f284a-b9c7-408a-b18e-5ba2c206a878",
          profile: AraPostAuthorProfile(
            id: "982",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/image_picker_FFB104A3-E747-4A1A-BB10-72349F02C2D3-71030-00000042097A75D5.jpg"),
            nickname: "용감한 외계인",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        comments: [],
        createdAt: Date(timeIntervalSince1970: 1699383299.051595),
        upvotes: 0,
        downvotes: 0,
        parentPost: 6176,
        parentComment: nil
      ),
      AraPostComment(
        id: 1551,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        myVote: nil,
        isMine: false,
        content: "123",
        author: AraPostAuthor(
          id: "984",
          username: "c7431c7c-adfa-44e5-8045-306535494ea1",
          profile: AraPostAuthorProfile(
            id: "984",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/default_pictures/blue-default1.png"),
            nickname: "신나는 포도",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        comments: [],
        createdAt: Date(timeIntervalSince1970: 1699887998.890784),
        upvotes: 0,
        downvotes: 0,
        parentPost: 6176,
        parentComment: nil
      )
    ]
  }
}
