//
//  AraPost+Mockable.swift
//  soap
//
//  Created by Soongyu Kwon on 06/08/2025.
//

import Foundation

extension AraPost: Mockable {
  static var mock: AraPost {
    AraPost(
      id: 6176,
      isHidden: false,
      hiddenReason: [],
      overrideHidden: nil,
      topic: nil,
      board: nil,
      title: "[Ara for KAIST] 아라만 깔아도 커피쿠폰을 준다고?",
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
      createdAt: Date(timeIntervalSince1970: 1699041272.944),
      isNSFW: false,
      isPolitical: false,
      views: 8,
      commentCount: 5,
      upvotes: 2,
      downvotes: 0,
      attachments: [],
      myCommentProfile: AraPostAuthor(
        id: "1142",
        username: "b68e0949-c924-4165-a183-380feb3eb3ea",
        profile: AraPostAuthorProfile(
          id: "1142",
          profilePictureURL: URL(string: "https://sparcs-newara-dev.s3.amazonaws.com/user_profiles/default_pictures/red-default2.png"),
          nickname: "귀여운 도토리",
          isOfficial: false,
          isSchoolAdmin: false
        ),
        isBlocked: nil
      ),
      isMine: false,
      comments: [
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
      ],
      content: "<p>안녕하세요, KAIST 학부 총학생회 산하 특별기구 SPARCS의&nbsp;Ara팀입니다.</p><p>딱, 오늘 하루, 아라앱만 깔아도 상품을 드립니다!</p><p><strong>📅 이벤트 기간</strong></p><ul><li><p>진행: 2025년 8월 14일 (목) 23:59</p></li><li><p>상품 지급: 2025년 8월 15일 (금)</p></li></ul><p><strong>👥 참여 대상</strong></p><ul><li><p>Ara를 사용하는 KAIST 구성원 전부</p></li></ul><p><strong>🖋 참여 방법</strong></p><ol><li><p>구글 플레이스토어 또는 앱스토어 에서 \"<strong>Ara for KAIST</strong>\"를 검색해서 설치해 주세요.</p></li><li><p><strong>KAIST IAM</strong>으로 Ara 앱에 로그인해 주세요.</p></li><li><p>Ara에 게시글을 작성하면 추첨을 통해 30분께 커피쿠폰을 드립니다!</p></li></ol><p><strong>🏆 상품</strong></p><ul><li><p><strong>참가상 (30명) </strong>: 스타벅스 아메리카노(R) 기프티콘</p></li></ul><p>앞으로 있을 다양한 이벤트에도 많은 관심 부탁드립니다.</p><p><br>카이스트만의 커뮤니티, Ara에 대한 많은 관심과 이용 부탁드립니다<br>Ara가 여러분의 일상을 함께 할 수 있는 서비스가 될 수 있도록 최선을 다하겠습니다!</p><p>감사합니다.</p><p>SPARCS&nbsp;Ara팀 드림</p>",
      myVote: nil,
      myScrap: false,
      scrapId: nil
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
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12327,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12326,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12325,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12318,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
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
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12316,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12315,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12250,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12240,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12239,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      ),
      AraPost(
        id: 12235,
        isHidden: false,
        hiddenReason: [],
        overrideHidden: nil,
        topic: nil,
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
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
        board: nil,
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
        upvotes: 1,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
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
        board: nil,
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
        upvotes: 0,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
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
        board: nil,
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
        upvotes: 1,
        downvotes: 0,
        attachments: nil,
        myCommentProfile: nil,
        isMine: nil,
        comments: [],
        content: nil,
        myVote: nil,
        myScrap: false,
        scrapId: nil
      )
    ]
  }
}
