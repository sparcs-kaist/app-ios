//
//  TaxiReportUser.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

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
              .foregroundStyle(Color.accentColor)
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
    TaxiProfilePhoto(url: user.profileImageURL)
      .frame(width: 36, height: 36)
  }
}
