//
//  PostView.swift
//  soap
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI

struct PostView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("[대학원 동아리 연합회] 대학원 동아리 연합회 소속이 되실 동아리를 모집합니다! (feat. 2022년 하반기 동아리 등록 심사 위원회)")
        .font(.headline)

      HStack {
        Text("22 May 2025 16:22")
        Text("485 views")
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      HStack {
        Circle()
          .frame(width: 28, height: 28)

        Text("류형욱(전산학부)")

        Image(systemName: "chevron.right")
      }
      .font(.subheadline)

      Divider()
        .padding(.vertical, 8)
    }
    .padding()
  }
}

#Preview {
  NavigationStack {
    PostView()
  }
}
