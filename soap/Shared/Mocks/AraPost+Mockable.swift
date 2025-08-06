//
//  AraPost+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

#if DEBUG
extension AraPost: Mockable {
  static var mock: AraPost {
    AraPost(
      id: 12328,
      isHidden: false,
      hiddenReason: [],
      overrideHidden: nil,
      topic: nil,
      title: "성인 정치글 22",
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
      attachmentType: .none,
      communicationArticleStatus: nil,
      createdAt: Date(),
      isNSFW: true,
      isPolitical: true,
      views: 1,
      commentCount: 0,
      positiveVoteCount: 0,
      negativeVoteCount: 0
    )
  }

  static var mockList: [AraPost] {
    [
      AraPost(
        id: 12328,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "성인 정치글 22",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: true,
        isPolitical: true,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12327,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "정치 성인글",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 2,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12326,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "성인글1",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: true,
        isPolitical: false,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12325,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "정치글1",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: true,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12318,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "포스터 게시판 테스트 2",
        author: AraPostAuthor(
          id: "1134",
          username: "5d47cbef-e7ae-428e-aa04-c1b987487405",
          profile: AraPostAuthorProfile(
            id: "1134",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/Chatroom_default1_KctlZWR.png"),
            nickname: "Ara",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        attachmentType: .image,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 2,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12317,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: AraBoardTopic(
          id: 13,
          slug: "money",
          name: LocalizedString([
            "ko": "돈",
            "en": "Money"
          ])
        ),
        title: "포스터 게시판 테스트 - 포스터가 없을 수 있습니다.",
        author: AraPostAuthor(
          id: "1134",
          username: "5d47cbef-e7ae-428e-aa04-c1b987487405",
          profile: AraPostAuthorProfile(
            id: "1134",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/Chatroom_default1_KctlZWR.png"),
            nickname: "Ara",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12316,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "포스터 게시판 테스트 2",
        author: AraPostAuthor(
          id: "1134",
          username: "5d47cbef-e7ae-428e-aa04-c1b987487405",
          profile: AraPostAuthorProfile(
            id: "1134",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/Chatroom_default1_KctlZWR.png"),
            nickname: "Ara",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        attachmentType: .image,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12315,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "포스터 게시판 테스트 1",
        author: AraPostAuthor(
          id: "1134",
          username: "5d47cbef-e7ae-428e-aa04-c1b987487405",
          profile: AraPostAuthorProfile(
            id: "1134",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/Chatroom_default1_KctlZWR.png"),
            nickname: "Ara",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        attachmentType: .image,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12250,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "gd",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 0,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12240,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "ㅎㅇㅎㅇ",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12239,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "안녕하세요",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 2,
        commentCount: 6,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12235,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        title: "dd",
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
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 1,
        commentCount: 0,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12233,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: AraBoardTopic(
          id: 10,
          slug: "lostfound",
          name: LocalizedString([
            "ko": "분실물",
            "en": "Lost & Found"
          ])
        ),
        title: "댓글 텟스트",
        author: AraPostAuthor(
          id: "1134",
          username: "5d47cbef-e7ae-428e-aa04-c1b987487405",
          profile: AraPostAuthorProfile(
            id: "1134",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/Chatroom_default1_KctlZWR.png"),
            nickname: "Ara",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 2,
        commentCount: 6,
        positiveVoteCount: 1,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12079,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: AraBoardTopic(
          id: 13,
          slug: "money",
          name: LocalizedString([
            "ko": "돈",
            "en": "Money"
          ])
        ),
        title: "테스트 (에디터 호환성 테스트)",
        author: AraPostAuthor(
          id: "1134",
          username: "5d47cbef-e7ae-428e-aa04-c1b987487405",
          profile: AraPostAuthorProfile(
            id: "1134",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/pictures/Chatroom_default1_KctlZWR.png"),
            nickname: "Ara",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        attachmentType: .none,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 3,
        commentCount: 1,
        positiveVoteCount: 0,
        negativeVoteCount: 0
      ),
      AraPost(
        id: 12043,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: AraBoardTopic(
          id: 12,
          slug: "game",
          name: LocalizedString([
            "ko": "게임",
            "en": "Game"
          ])
        ),
        title: "gif 테스트",
        author: AraPostAuthor(
          id: "987",
          username: "4a61bb61-fcba-492f-a19b-ba11fb3c9b12",
          profile: AraPostAuthorProfile(
            id: "987",
            profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/default_pictures/red-default2.png"),
            nickname: "가냘픈 사자",
            isOfficial: false,
            isSchoolAdmin: false
          ),
          isBlocked: false
        ),
        attachmentType: .image,
        communicationArticleStatus: nil,
        createdAt: Date(),
        isNSFW: false,
        isPolitical: false,
        views: 2,
        commentCount: 0,
        positiveVoteCount: 1,
        negativeVoteCount: 0
      )
    ]
  }
}
#endif 