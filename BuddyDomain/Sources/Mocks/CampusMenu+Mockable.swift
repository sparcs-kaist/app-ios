//
//  CampusMenu+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation

public extension CafeteriaMenu {
  static var mockList: [CafeteriaMenu] {
    let today = Calendar.current.startOfDay(for: .now)
    return [
      CafeteriaMenu(placeID: "N11", date: today, meals: [
        CafeteriaMeal(kind: .breakfast, serving: .init((8, 0), (9, 0)), courses: [
          CafeteriaCourse(id: "n11-b1", name: "Korean", dishes: ["백미밥", "콩나물국", "계란말이", "김구이", "배추김치"], price: 1000, calories: 640),
          CafeteriaCourse(id: "n11-b2", name: "Takeaway", dishes: ["햄치즈 토스트", "바나나", "우유"], price: 2500, calories: 520)
        ]),
        CafeteriaMeal(kind: .lunch, serving: .init((11, 30), (13, 30)), courses: [
          CafeteriaCourse(id: "n11-l1", name: "Korean", dishes: ["흑미밥", "된장찌개", "제육볶음", "숙주나물", "깍두기"], price: 5000, calories: 890),
          CafeteriaCourse(id: "n11-l2", name: "Special", dishes: ["돈까스 카레", "양배추 샐러드", "단무지", "요구르트"], price: 6000, calories: 1020),
          CafeteriaCourse(id: "n11-l3", name: "Noodles", dishes: ["얼큰 짬뽕", "군만두", "단무지"], price: 5500, calories: 870)
        ]),
        CafeteriaMeal(kind: .dinner, serving: .init((17, 30), (19, 0)), courses: [
          CafeteriaCourse(id: "n11-d1", name: "Korean", dishes: ["백미밥", "김치찌개", "고등어구이", "시금치나물", "배추김치"], price: 5000, calories: 830),
          CafeteriaCourse(id: "n11-d2", name: "Rice bowl", dishes: ["치킨마요 덮밥", "미소된장국", "단무지"], price: 5500, calories: 940)
        ])
      ]),
      CafeteriaMenu(placeID: "E-cafeteria", date: today, meals: [
        CafeteriaMeal(kind: .lunch, serving: .init((11, 30), (13, 30)), courses: [
          CafeteriaCourse(id: "e-l1", name: "Set menu", dishes: ["잡곡밥", "순두부찌개", "닭갈비", "무생채", "배추김치"], price: 5500, calories: 910),
          CafeteriaCourse(id: "e-l2", name: "Special", dishes: ["수제 함박스테이크", "볶음밥", "콘샐러드", "음료"], price: 6500, calories: 1080)
        ]),
        CafeteriaMeal(kind: .dinner, serving: .init((17, 30), (19, 0)), courses: [
          CafeteriaCourse(id: "e-d1", name: "Set menu", dishes: ["백미밥", "부대찌개", "어묵볶음", "배추김치"], price: 5500, calories: 860)
        ])
      ]),
      CafeteriaMenu(placeID: "E5", date: today, meals: [
        CafeteriaMeal(kind: .lunch, serving: .init((11, 30), (13, 30)), courses: [
          CafeteriaCourse(id: "e5-l1", name: "Weekly special", dishes: ["소불고기 전골", "현미밥", "잡채", "샐러드바"], price: 7000, calories: 950)
        ])
      ]),
      CafeteriaMenu(placeID: "N6", date: today, meals: [
        CafeteriaMeal(kind: .lunch, serving: .init((11, 30), (13, 30)), courses: [
          CafeteriaCourse(id: "n6-l1", name: "Buffet", dishes: ["오늘의 뷔페", "샐러드바", "디저트"], price: 7500)
        ]),
        CafeteriaMeal(kind: .dinner, serving: .init((17, 30), (19, 0)), courses: [
          CafeteriaCourse(id: "n6-d1", name: "Light", dishes: ["비빔밥", "미역국", "배추김치"], price: 6000, calories: 720)
        ])
      ])
    ]
  }
}

public extension RestaurantMenu {
  static var mockList: [RestaurantMenu] {
    [
      RestaurantMenu(placeID: "wellchai", sections: [
        RestaurantMenuSection(id: "noodles", title: "Noodles", items: [
          RestaurantMenuItem(id: "w1", name: "짜장면", detail: "Jjajangmyeon", price: 6000, isPopular: true),
          RestaurantMenuItem(id: "w2", name: "짬뽕", detail: "Spicy seafood noodles", price: 7500, isPopular: true),
          RestaurantMenuItem(id: "w3", name: "간짜장", detail: "Dry-fried black bean sauce", price: 7000)
        ]),
        RestaurantMenuSection(id: "rice", title: "Rice", items: [
          RestaurantMenuItem(id: "w4", name: "볶음밥", detail: "Fried rice", price: 7000),
          RestaurantMenuItem(id: "w5", name: "마파두부밥", detail: "Mapo tofu rice", price: 7500)
        ]),
        RestaurantMenuSection(id: "sides", title: "To share", items: [
          RestaurantMenuItem(id: "w6", name: "탕수육 (소)", detail: "Sweet and sour pork, small", price: 15000, isPopular: true),
          RestaurantMenuItem(id: "w7", name: "군만두", detail: "Fried dumplings", price: 5000)
        ])
      ]),
      RestaurantMenu(placeID: "rolling-pasta", sections: [
        RestaurantMenuSection(id: "pasta", title: "Pasta", items: [
          RestaurantMenuItem(id: "r1", name: "토마토 파스타", detail: "Tomato", price: 7900, isPopular: true),
          RestaurantMenuItem(id: "r2", name: "크림 파스타", detail: "Cream and bacon", price: 8900),
          RestaurantMenuItem(id: "r3", name: "로제 파스타", detail: "Rosé", price: 8900, isPopular: true)
        ]),
        RestaurantMenuSection(id: "sides", title: "Sides", items: [
          RestaurantMenuItem(id: "r4", name: "갈릭 브레드", detail: "Garlic bread", price: 3000)
        ])
      ]),
      RestaurantMenu(placeID: "little-hanoi", sections: [
        RestaurantMenuSection(id: "pho", title: "Pho", items: [
          RestaurantMenuItem(id: "h1", name: "소고기 쌀국수", detail: "Beef pho", price: 8500, isPopular: true),
          RestaurantMenuItem(id: "h2", name: "분짜", detail: "Bún chả", price: 9500)
        ]),
        RestaurantMenuSection(id: "rice", title: "Rice", items: [
          RestaurantMenuItem(id: "h3", name: "파인애플 볶음밥", detail: "Pineapple fried rice", price: 8500)
        ])
      ]),
      RestaurantMenu(placeID: "bears-taco", sections: [
        RestaurantMenuSection(id: "tacos", title: "Tacos", items: [
          RestaurantMenuItem(id: "t1", name: "Chicken taco (2)", price: 6500, isPopular: true),
          RestaurantMenuItem(id: "t2", name: "Beef burrito", price: 8900),
          RestaurantMenuItem(id: "t3", name: "Quesadilla", price: 7900)
        ])
      ]),
      RestaurantMenu(placeID: "subway", sections: [
        RestaurantMenuSection(id: "15cm", title: "15 cm", items: [
          RestaurantMenuItem(id: "s1", name: "Italian B.M.T.", price: 6900, isPopular: true),
          RestaurantMenuItem(id: "s2", name: "Egg Mayo", price: 5500, isPopular: true),
          RestaurantMenuItem(id: "s3", name: "Steak & Cheese", price: 7900)
        ])
      ]),
      RestaurantMenu(placeID: "insaeng", sections: [
        RestaurantMenuSection(id: "soup", title: "Soup", items: [
          RestaurantMenuItem(id: "i1", name: "설렁탕", detail: "Ox bone soup", price: 9000, isPopular: true),
          RestaurantMenuItem(id: "i2", name: "도가니탕", detail: "Knee bone soup", price: 12000)
        ])
      ]),
      RestaurantMenu(placeID: "yukjeon", sections: [
        RestaurantMenuSection(id: "udon", title: "Udon", items: [
          RestaurantMenuItem(id: "y1", name: "옛날우동", detail: "Classic udon", price: 4500, isPopular: true),
          RestaurantMenuItem(id: "y2", name: "냉모밀", detail: "Cold soba", price: 6000)
        ])
      ]),
      RestaurantMenu(placeID: "pulbitmaru", sections: [
        RestaurantMenuSection(id: "buffet", title: "Buffet", items: [
          RestaurantMenuItem(id: "p1", name: "Salad & rice plate", detail: "Per 100 g", price: 1700, isPopular: true)
        ])
      ]),
      RestaurantMenu(placeID: "dddn-pizza", sections: [
        RestaurantMenuSection(id: "pizza", title: "Pizza", items: [
          RestaurantMenuItem(id: "d1", name: "Pepperoni (L)", price: 18900, isPopular: true),
          RestaurantMenuItem(id: "d2", name: "Potato bacon (L)", price: 20900)
        ])
      ])
    ]
  }
}
