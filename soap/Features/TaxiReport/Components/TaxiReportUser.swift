//
//  TaxiReportUser.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import SwiftUI
import NukeUI

struct TaxiReportUser: View {
  var user: TaxiParticipant
  
  var body: some View {
    HStack {
      userProfileImage
      Text(user.nickname)
      // TODO: 정산 상태
    }
  }
  
  private var userProfileImage: some View {
    Group {
      if let url = user.profileImageURL {
        LazyImage(url: url) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Circle()
              .fill(Color.secondarySystemBackground)
          }
        }
        .frame(width: 36, height: 36)
        .clipShape(.circle)
      } else {
        Circle()
          .fill(Color.secondarySystemBackground)
          .frame(width: 36, height: 36)
      }
    }
  }
}
