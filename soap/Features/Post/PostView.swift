//
//  PostView.swift
//  soap
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI

struct PostView: View {
  @State private var htmlHeight: CGFloat = .zero

  var body: some View {
    ScrollView {
      header

//      content

      footer
    }
    .padding()
  }

  @ViewBuilder
  private var footer: some View {
    HStack {
      Button("downvote", systemImage: "arrow.down") {

      }
      .labelStyle(.iconOnly)
    }
  }

  @ViewBuilder
  private var content: some View {
    let contentString = """
    <p>안녕하세요! 기계동 정문 왼편에서 4년째 사랑받아 온 ‘오샐러드’입니다.<br>우리가게 오늘도 정상 영업 중입니다.<br>새롭게 선보이는 사이드 메뉴와 풍성한 할인 이벤트로 여러분을 찾아갑니다!<br><br>🎉세트 메뉴로 더 푸짐하고, 더 건강하게! 오샐러드 세트 할인 이벤트🎉<br><br>건강한 한 끼, 오샐러드에서 든든하게 즐기세요!<br>이제, 더 많은 메뉴를 더 저렴하게 즐길 수 있는 기회!<br>세트 할인 메뉴로 더욱 푸짐하고, 알차게 챙기세요! 🥑<br><br>🎁 [오샐러드] 세트 할인 메뉴 및 영양성분<br><br>닭가슴살 샐러드 세트 (칼로리: 592.7 kcal, 단백질: 31.8 g, 탄수화물: 111.4 g, 지방: 4.55 g / 파스타 기준, 쿠키 제외)<br>• 닭가슴살 샐러드(곡물 or 파스타) +단백질쿠키(더블초코 or 피넛버터) 택 1 +제로아이스티(복숭아 or 자몽) 택 1 = 정가 10,000원 할인가 7,000원<br><br>단호박 샐러드 세트 (칼로리: 661.0 kcal, 단백질: 22.2 g, 탄수화물: 120.0 g, 지방: 14.3 g / 파스타 기준)<br>• 단호박 샐러드(곡물 or 파스타) +단백질쿠키(더블초코 or 피넛버터) 택 1 +제로아이스티(복숭아 or 자몽) 택 1 = 정가 10,300원 할인가 7,300원<br><br>두부 샐러드 세트 (771.8 kcal, 단백질: 38.0 g, 탄수화물: 116.7 g, 지방: 21.7 g / 파스타 기준)<br>• 두부 샐러드(곡물 or 파스타) +단백질쿠키(더블초코 or 피넛버터) 택 1 +제로아이스티(복숭아 or 자몽) 택 1 = 정가 10,400원 할인가 7400원<br><br>콥 샐러드 세트 (803.0 kcal, 단백질: 33.9 g, 탄수화물: 114.8 g, 지방: 25.9 g / 파스타 기준)<br>• 콥 샐러드(곡물 or 파스타) +단백질쿠키(더블초코 or 피넛버터) 택 1 +제로아이스티(복숭아 or 자몽) 택 1 = 정가 10,600원 할인가 7,600원<br><br>밸런스 세트 (776.3 kcal, 단백질: 36.2 g, 탄수화물: 129.8 g, 지방: 15.8 g / 파스타 기준)<br>• 밸런스 샐러드(곡물 or 파스타) +단백질쿠키(더블초코 or 피넛버터) 택 1 +제로아이스티(복숭아 or 자몽) 택 1 = 정가 11,500원 할인가 8,500원<br><br>단백질 쿠키<br>• 더블초코 : (175kcal, 단백질 : 7g, 탄수화물 : 20g, 지방 : 8g)<br>• 피넛버터 : (165kcal, 단백질 : 9g, 탄수화물 : 20g, 지방 : 6g)<br><br>📍 위치: [대전광역시 유성구 대학로 291 N7-1, 1층 ]<br>📞 문의: [0507-1336-3599]<br>🛵 단체 주문 가능 (전화 문의)<br>건강하게, 맛있게, 부담 없이!<br>지금 바로 오샐러드에서 세트 할인 메뉴로 더욱 맛있는 한 끼를 즐겨보세요.💚<br><br>※ 본 영양성분은 샐러드 정량과 fatsecret 의 표기를 따랐으며 오차가 있을 수 있습니다.<img src=\"https://sparcs-newara.s3.amazonaws.com/files/2_sjYcz0g.png\" width=\"500\" data-attachment=\"160726\"><img src=\"https://sparcs-newara.s3.amazonaws.com/files/3_AWZYwn6.png\" width=\"500\" data-attachment=\"160729\"><img src=\"https://sparcs-newara.s3.amazonaws.com/files/4_1jTOofj.jpg\" width=\"500\" data-attachment=\"160727\"><img src=\"https://sparcs-newara.s3.amazonaws.com/files/5_WvjnOsH.jpg\" width=\"500\" data-attachment=\"160728\"></p>
    """

    HTMLView(contentHeight: $htmlHeight, htmlString: contentString)
      .frame(height: htmlHeight)
      .border(.red)
  }

  private var header: some View {
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
        .padding(.vertical, 4)
    }
  }
}

#Preview {
  NavigationStack {
    PostView()
  }
}
