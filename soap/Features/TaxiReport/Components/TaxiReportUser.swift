//
//  TaxiReportUser.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import SwiftUI
import NukeUI
import BuddyDomain

struct TaxiReportUser: View {
  var user: TaxiParticipant
  
  var body: some View {
    HStack {
      userProfileImage
      VStack(alignment: .leading) {
        HStack {
          Text(user.nickname)
          
          if user.badge {
            Image(systemName: "phone.circle.fill")
              .foregroundStyle(.accent)
              .scaleEffect(0.8)
          }
        }
        if user.isSettlement != .notDeparted {
          Text(
            user.isSettlement == .requestedSettlement ? "Requested settlement" :
            user.isSettlement == .paymentSent ? "Paid" : "Not paid"
          )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
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
