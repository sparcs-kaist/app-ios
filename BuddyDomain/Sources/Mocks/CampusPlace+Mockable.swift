//
//  CampusPlace+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import Foundation

// Coordinates, names, categories and the shop hours come from the KAIST POI sheet
// (sparcsapp-back `scripts/poi_*.csv`); summaries and menus are made up for design work.

extension CampusPlace: Mockable { }

public extension CampusPlace {
  static var mock: CampusPlace {
    mockList.first { $0.id == "N11" }!
  }

  static var mockList: [CampusPlace] {
    buildings + dining + cafes + services + olevStops
  }

  /// Stands in for the user's location until the map asks for it: the path between Taeul and the
  /// Sports Complex, roughly the middle of campus.
  static let mockCurrentLatitude = 36.37225
  static let mockCurrentLongitude = 127.36045

  private static let buildings: [CampusPlace] = [
    CampusPlace(
      id: "E1", code: "E1", name: "Main Gate", nameKo: "정문", category: .gate,
      latitude: 36.365596, longitude: 127.363944, keywords: ["Main Gate", "정문"],
      summary: "The main entrance on Daehak-ro, with the taxi rank and the OLEV Main Gate stop just inside."
    ),
    CampusPlace(
      id: "N0", code: "N0", name: "East Gate", nameKo: "동문", category: .gate,
      latitude: 36.373608, longitude: 127.366637
    ),
    CampusPlace(
      id: "E14", code: "E14", name: "Main Administration Building", nameKo: "본관", category: .building,
      latitude: 36.370518, longitude: 127.361264, keywords: ["본관", "Admin"],
      summary: "Home to the President's Office and most central administration offices.",
      openingHours: .weekdays(.init((9, 0), (18, 0)))
    ),
    CampusPlace(
      id: "E11", code: "E11", name: "Creative Learning Building", nameKo: "창의학습관", category: .academicBuilding,
      latitude: 36.370344, longitude: 127.362555,
      keywords: ["창학", "창습관", "창의관", "입학처", "Office of Admissions"],
      summary: "Lecture halls used by most first-year courses, plus the Office of Admissions and Student Affairs.",
      openingHours: .everyDay(.init((7, 0), (23, 0))),
      floor: "B1–5F"
    ),
    CampusPlace(
      id: "E3", code: "E3", name: "Information & Electronics Building", nameKo: "정보전자공학동", category: .building,
      latitude: 36.368002, longitude: 127.365033, keywords: ["EE", "전자과", "전산"]
    ),
    CampusPlace(
      id: "E9", code: "E9", name: "Academic Cultural Complex", nameKo: "학술문화관", category: .library,
      latitude: 36.369367, longitude: 127.362721,
      keywords: ["도서관", "문화관", "Main Library", "Cultural Building"],
      summary: "The main library: open stacks, group study rooms you can book online and a 24-hour reading room on 1F.",
      openingHours: .weekdays(.init((9, 0), (22, 0)), saturday: [.init((10, 0), (17, 0))], sunday: [.init((10, 0), (17, 0))]),
      hoursNote: "24-hour reading room open every day",
      floor: "B1–5F"
    ),
    CampusPlace(
      id: "E15", code: "E15", name: "Auditorium", nameKo: "대강당", category: .theater,
      latitude: 36.372062, longitude: 127.362911,
      summary: "The campus's largest hall, used for convocation, concerts and the spring festival."
    ),
    CampusPlace(
      id: "E17", code: "E17", name: "Stadium", nameKo: "운동장", category: .sportsField,
      latitude: 36.369583, longitude: 127.368515,
      summary: "Running track and football pitch, open to everyone outside reserved hours.",
      openingHours: .everyDay(.init((6, 0), (23, 0)))
    ),
    CampusPlace(
      id: "E21", code: "E21", name: "KAIST Clinic-Papalardo Center", nameKo: "KAIST 클리닉-파팔라도 센터", category: .hospital,
      latitude: 36.369386, longitude: 127.369829, keywords: ["약국", "Pharmacy", "병원"],
      summary: "Primary care, dental and mental health clinics for students and staff, with a pharmacy on 1F.",
      openingHours: .weekdays(.init((9, 0), (12, 0)), .init((13, 0), (18, 0)), saturday: [.init((9, 0), (13, 0))]),
      hoursNote: "Closed on public holidays"
    ),
    CampusPlace(
      id: "N3", code: "N3", name: "RyuGeunChul Sports Complex", nameKo: "류근철 스포츠컴플렉스", category: .sportsField,
      latitude: 36.372511, longitude: 127.361584, keywords: ["헬스장", "Gym", "Swimming pool", "수영장"],
      summary: "Gym, swimming pool and indoor courts. Bring your student ID.",
      openingHours: .weekdays(.init((6, 0), (22, 0)), saturday: [.init((9, 0), (18, 0))])
    ),
    CampusPlace(
      id: "N10", code: "N10", name: "Undergraduate Branch Library", nameKo: "교양분관", category: .library,
      latitude: 36.374206, longitude: 127.360406, keywords: ["교분", "자전거"],
      summary: "Study spaces close to the north dorms; quieter than the main library during exams.",
      openingHours: .everyDay(.allDay)
    ),
    CampusPlace(
      id: "N13", code: "N13", name: "Tae Wul Gwan", nameKo: "태울관", category: .building,
      latitude: 36.373185, longitude: 127.359878, keywords: ["태울", "동아리"],
      summary: "Student clubs and a row of small restaurants on the ground floor."
    ),
    CampusPlace(
      id: "N14", code: "N14", name: "Sarang Hall", nameKo: "사랑관", category: .dormitory,
      latitude: 36.373702, longitude: 127.358345
    ),
    CampusPlace(
      id: "W4-4", code: "W4-4", name: "Heemang Hall", nameKo: "희망관", category: .dormitory,
      latitude: 36.368471, longitude: 127.356758
    ),
    CampusPlace(
      id: "W6", code: "W6", name: "Mir and Narae Hall", nameKo: "미르/나래관", category: .dormitory,
      latitude: 36.370568, longitude: 127.3557255, keywords: ["미르관", "나래관"]
    ),
    CampusPlace(
      id: "W2", code: "W2", name: "Student Center - 1", nameKo: "학생회관 - 1", category: .building,
      latitude: 36.367194, longitude: 127.360935,
      summary: "West-campus student centre with a convenience store, pizza and lunch boxes."
    ),
    CampusPlace(
      id: "W9", code: "W9", name: "Outdoor Theater", nameKo: "노천극장", category: .theater,
      latitude: 36.370744, longitude: 127.357965
    ),
    CampusPlace(
      id: "W-sports", name: "West Sports Complex", nameKo: "서측 체육관", category: .sportsField,
      latitude: 36.367086, longitude: 127.360688,
      keywords: ["농구", "배구", "라켓볼", "탁구", "Basketball", "Volleyball", "Racquetball", "Table Tennis"],
      openingHours: .everyDay(.init((6, 0), (24, 0)))
    )
  ]

  private static let dining: [CampusPlace] = [
    CampusPlace(
      id: "N11", code: "N11", name: "Cafeteria", nameKo: "학생식당", category: .cafeteria,
      latitude: 36.373643, longitude: 127.359197, keywords: ["카이마루", "카마", "Kaimaru", "학식", "북측식당"],
      summary: "Kaimaru — the north-campus food court. The student cafeteria serves three meals a day, surrounded by a dozen independent counters.",
      openingHours: .everyDay(.init((8, 0), (9, 0)), .init((11, 30), (13, 30)), .init((17, 30), (19, 0))),
      hoursNote: "Breakfast is weekdays only",
      floor: "1F"
    ),
    CampusPlace(
      id: "E-cafeteria", name: "East-Campus Cafeteria", nameKo: "동맛골", category: .cafeteria,
      latitude: 36.369021, longitude: 127.363794, keywords: ["동맛골", "학식"],
      summary: "Two counters on the east side of campus: a set menu and a rotating special.",
      openingHours: .weekdays(.init((11, 30), (13, 30)), .init((17, 30), (19, 0))),
      hoursNote: "Closed on weekends and public holidays",
      floor: "B1"
    ),
    CampusPlace(
      id: "E5", code: "E5", name: "Facility Club", nameKo: "교직원회관", category: .cafeteria,
      latitude: 36.369263, longitude: 127.363563, keywords: ["패컬티클럽"],
      summary: "Staff dining hall that welcomes students. A quieter lunch with a weekly special.",
      openingHours: .weekdays(.init((11, 30), (13, 30))),
      floor: "2F"
    ),
    CampusPlace(
      id: "N6", code: "N6", name: "Faculty Hall", nameKo: "교수회관", category: .cafeteria,
      latitude: 36.374612, longitude: 127.364759,
      summary: "Buffet-style lunch and a lighter dinner menu.",
      openingHours: .weekdays(.init((11, 30), (13, 30)), .init((17, 30), (19, 0)))
    ),
    CampusPlace(
      id: "wellchai", name: "Wellchai", nameKo: "웰차이", category: .restaurant,
      latitude: 36.373662, longitude: 127.359400, buildingCode: "N11", keywords: ["Chinese", "중식", "짜장면"],
      summary: "Chinese comfort food. The jjajangmyeon is the late-night favourite.",
      openingHours: .everyDay(.init((10, 30), (21, 0))),
      floor: "N11 1F"
    ),
    CampusPlace(
      id: "rolling-pasta", name: "Rolling Pasta", nameKo: "롤링파스타", category: .restaurant,
      latitude: 36.373762, longitude: 127.359406, buildingCode: "N11", keywords: ["Pasta", "파스타"],
      openingHours: .everyDay(.init((11, 0), (20, 30))),
      floor: "N11 1F"
    ),
    CampusPlace(
      id: "little-hanoi", name: "Little HANOI", nameKo: "리틀하노이", category: .restaurant,
      latitude: 36.373625, longitude: 127.358998, buildingCode: "N11", keywords: ["Vietnamese", "쌀국수", "Pho"],
      openingHours: .weekdays(.init((11, 0), (20, 0)), saturday: [.init((11, 0), (19, 0))]),
      floor: "N11 1F"
    ),
    CampusPlace(
      id: "bears-taco", name: "BEARS TACO", nameKo: "베어스타코", category: .restaurant,
      latitude: 36.373800, longitude: 127.359406, buildingCode: "N11", keywords: ["Mexican", "타코"],
      openingHours: .weekdays(.init((11, 0), (20, 0))),
      floor: "N11 1F"
    ),
    CampusPlace(
      id: "onigiri", name: "Onigiri & Gyudon", nameKo: "오니기리와 이규동", category: .restaurant,
      latitude: 36.373714, longitude: 127.359400, buildingCode: "N11", keywords: ["Japanese", "규동"],
      openingHours: .weekdays(.init((10, 30), (20, 0))),
      floor: "N11 1F"
    ),
    CampusPlace(
      id: "pulbitmaru", name: "PULBITMARU", nameKo: "풀빛마루", category: .restaurant,
      latitude: 36.374280, longitude: 127.359883, buildingCode: "N12", keywords: ["풀마", "Buffet"],
      summary: "Weighed salad-and-rice buffet; pay by the plate.",
      openingHours: .weekdays(.init((11, 30), (14, 0)), .init((17, 0), (19, 30))),
      floor: "N12 2F"
    ),
    CampusPlace(
      id: "insaeng", name: "Insaeng Seolleongtang", nameKo: "인생설렁탕", category: .restaurant,
      latitude: 36.373101, longitude: 127.360036, buildingCode: "N13", keywords: ["설렁탕", "Korean"],
      openingHours: .everyDay(.init((10, 0), (21, 0))),
      floor: "N13 1F"
    ),
    CampusPlace(
      id: "yukjeon", name: "Yukjeon Udon", nameKo: "역전우동", category: .restaurant,
      latitude: 36.372988, longitude: 127.360036, buildingCode: "N13", keywords: ["우동", "Udon"],
      openingHours: .everyDay(.init((10, 0), (24, 0))),
      floor: "N13 1F"
    ),
    CampusPlace(
      id: "subway", name: "SUBWAY", nameKo: "SUBWAY", category: .restaurant,
      latitude: 36.371271, longitude: 127.362037, buildingCode: "E16", keywords: ["써브웨이", "Sandwich"],
      openingHours: .weekdays(.init((8, 0), (21, 0)), saturday: [.init((10, 0), (19, 0))]),
      floor: "E16 1F"
    ),
    CampusPlace(
      id: "dddn-pizza", name: "DDDN Pizza", nameKo: "대덕동네피자", category: .restaurant,
      latitude: 36.367212, longitude: 127.360828, buildingCode: "W2", keywords: ["피자", "pizza"],
      openingHours: .everyDay(.init((11, 0), (23, 0))),
      floor: "W2 1F"
    ),
    CampusPlace(
      id: "big-dosirak", name: "The Big Dosirak", nameKo: "더큰도시락", category: .restaurant,
      latitude: 36.366893, longitude: 127.360467, buildingCode: "W2", keywords: ["도시락"],
      openingHours: .weekdays(.init((10, 0), (20, 0))),
      floor: "W2 1F"
    )
  ]

  private static let cafes: [CampusPlace] = [
    CampusPlace(
      id: "tom-n-toms", name: "Tom and Toms", nameKo: "탐앤탐스", category: .cafe,
      latitude: 36.374096, longitude: 127.365323, buildingCode: "N1", keywords: ["카페", "Cafe"],
      openingHours: .everyDay(.init((8, 0), (24, 0))),
      floor: "N1 1F"
    ),
    CampusPlace(
      id: "angelinus", name: "Angel-in-us", nameKo: "엔젤리너스", category: .cafe,
      latitude: 36.372991, longitude: 127.360471, buildingCode: "N13-1", keywords: ["카페", "Cafe"],
      openingHours: .everyDay(.init((8, 0), (22, 0))),
      floor: "N13-1 1F"
    ),
    CampusPlace(
      id: "grazie", name: "Grazie", nameKo: "그라지에", category: .cafe,
      latitude: 36.3682, longitude: 127.363571, buildingCode: "E4", keywords: ["카페", "Cafe"],
      openingHours: .weekdays(.init((8, 0), (19, 0))),
      floor: "E4 1F"
    ),
    CampusPlace(
      id: "pascucci", name: "Caffè Pascucci", nameKo: "파스쿠찌", category: .cafe,
      latitude: 36.368621, longitude: 127.364585, buildingCode: "E3", keywords: ["카페", "Cafe"],
      openingHours: .weekdays(.init((8, 0), (20, 0)), saturday: [.init((10, 0), (18, 0))]),
      floor: "E3 1F"
    ),
    CampusPlace(
      id: "california", name: "California bakery&cafe", nameKo: "캘리포니아 베이커리&카페", category: .cafe,
      latitude: 36.370077, longitude: 127.363687, buildingCode: "E6-5", keywords: ["카페", "Cafe", "빵"],
      openingHours: .weekdays(.init((7, 30), (19, 0))),
      floor: "E6-5 1F"
    ),
    CampusPlace(
      id: "droptop", name: "Cafe Droptop", nameKo: "카페 드롭탑", category: .cafe,
      latitude: 36.370053, longitude: 127.359902, buildingCode: "W8", keywords: ["Cafe", "카페"],
      openingHours: .weekdays(.init((8, 0), (20, 0))),
      floor: "W8 1F"
    ),
    CampusPlace(
      id: "juiceking", name: "JUICEKING", nameKo: "쥬스킹", category: .cafe,
      latitude: 36.373574, longitude: 127.359001, buildingCode: "N11", keywords: ["주스", "Juice"],
      openingHours: .everyDay(.init((9, 0), (21, 0))),
      floor: "N11 1F"
    )
  ]

  private static let services: [CampusPlace] = [
    CampusPlace(
      id: "cvs-n12", name: "Convenience Store", nameKo: "매점", category: .store,
      latitude: 36.374224, longitude: 127.359867, buildingCode: "N12", keywords: ["CVS", "편의점"],
      openingHours: .everyDay(.allDay),
      hoursNote: "Open 24 hours (unmanned overnight)",
      floor: "N12 1F"
    ),
    CampusPlace(
      id: "cvs-e5", name: "Convenience Store", nameKo: "매점", category: .store,
      latitude: 36.369205, longitude: 127.36377, buildingCode: "E5", keywords: ["CVS", "편의점"],
      openingHours: .weekdays(.init((9, 0), (19, 0))),
      hoursNote: "Closed on weekends and public holidays",
      floor: "E5 1F"
    ),
    CampusPlace(
      id: "general-store", name: "General store", nameKo: "잡화점", category: .store,
      latitude: 36.373286, longitude: 127.360181, buildingCode: "N13", keywords: ["안경점", "CVS", "매점"],
      openingHours: .weekdays(.init((9, 0), (20, 0)), saturday: [.init((10, 0), (17, 0))]),
      floor: "N13 1F"
    ),
    CampusPlace(
      id: "brand-shop", name: "KAIST Brand Shop", nameKo: "KAIST 브랜드 샵", category: .store,
      latitude: 36.36974, longitude: 127.362238, buildingCode: "E14", keywords: ["굿즈", "Merch"],
      summary: "Hoodies, notebooks and Nupjuk plushies.",
      openingHours: .weekdays(.init((10, 0), (18, 0)), saturday: [.init((12, 0), (17, 0))], sunday: [.init((12, 0), (17, 0))]),
      hoursNote: "Closed on public holidays"
    ),
    CampusPlace(
      id: "print-e9", name: "Print Shop", nameKo: "오비기획", category: .printShop,
      latitude: 36.369045, longitude: 127.363043, buildingCode: "E9", keywords: ["인쇄", "Print"],
      openingHours: .weekdays(.init((9, 0), (18, 0))),
      hoursNote: "Closed on weekends and public holidays",
      floor: "E9 B1"
    ),
    CampusPlace(
      id: "post-office", name: "KAIST Post Office", nameKo: "한국과학기술원우편취급국", category: .postOffice,
      latitude: 36.373986, longitude: 127.359701, buildingCode: "N11", keywords: ["우체국", "Post"],
      openingHours: .weekdays(.init((9, 0), (18, 0))),
      hoursNote: "Closed on weekends and public holidays",
      floor: "N11 1F"
    )
  ]

  /// The OLEV stops in route order, as in `scripts/poi_olev.csv` (codes there are `O1`…; KAIST signs
  /// them `OV1`…).
  static let olevStops: [CampusPlace] = [
    ("OV1", "Cafeteria Stop", "북측식당 정류장", 36.373438, 127.358923),
    ("OV2", "Sports Complex Stop", "스포츠컴플렉스 정류장", 36.372623, 127.362131),
    ("OV3", "Creative Learning Building Stop", "창의학습관 정류장", 36.370736, 127.362783),
    ("OV4", "Biomedical Research Center Stop", "의과학연구센터 정류장", 36.370278, 127.365945),
    ("OV5", "KAIST Clinic Stop", "KAIST 클리닉 정류장", 36.369522, 127.369456),
    ("OV6", "NNFC Stop", "나노종합기술원 정류장", 36.367611, 127.366825),
    ("OV7", "Main Gate Stop", "정문 정류장", 36.366276, 127.363606),
    ("OV8", "Materials Science and Engineering Building Stop", "신소재공학동 정류장", 36.364954, 127.361704),
    ("OV9", "KISTI Stop", "KISTI 정류장", 36.364647, 127.358604),
    ("OV10", "W4 Dormitory Stop", "희망·다솜관 정류장", 36.36814, 127.356324),
    ("OV11", "International Faculty APT Stop", "외국인교수아파트 정류장", 36.371418, 127.355635)
  ].map { code, name, nameKo, latitude, longitude in
    CampusPlace(
      id: code, code: code, name: name, nameKo: nameKo, category: .olevStop,
      latitude: latitude, longitude: longitude, keywords: ["OLEV", "올레브", "셔틀", "버스", "Shuttle", "Bus"],
      summary: "Free campus shuttle for students, staff and visitors. Runs a one-way loop of eleven stops on weekdays.",
      hoursNote: "Weekdays only · 26 runs a day",
      phoneNumber: "042-350-2316"
    )
  }
}

public extension OLEVTimetable {
  /// The weekday OLEV timetable from the KAIST website, with two minutes between stops assumed
  /// until the API gives real offsets.
  static var mock: OLEVTimetable {
    let departures = [
      "8:40", "8:55", "9:15", "9:35", "9:55", "10:10", "10:25", "10:45", "11:05", "11:25", "11:45",
      "12:40", "12:55", "13:15", "13:35", "13:55", "14:10", "14:25", "14:45", "15:05", "15:25",
      "15:40", "15:55", "16:15", "16:35", "16:55"
    ].map { time in
      let parts = time.split(separator: ":").compactMap { Int($0) }
      return parts[0] * 60 + parts[1]
    }
    return OLEVTimetable(
      departures: departures,
      stops: CampusPlace.olevStops.enumerated().map { index, stop in
        .init(
          placeID: stop.id,
          offset: index * 2,
          path: olevRoadPaths[index].map { PathPoint(latitude: $0.0, longitude: $0.1) }
        )
      }
    )
  }

  /// Roads between consecutive stops, from Apple Maps driving directions, so the route follows the
  /// campus roads until the API serves the real path. Index *i* runs from stop *i* to the next, and
  /// the last leg returns to the first stop.
  private static let olevRoadPaths: [[(Double, Double)]] = [
    // OV1 → OV2
    [
      (36.373453, 127.358923), (36.373448, 127.359493), (36.373499, 127.359885), (36.373490, 127.361086),
      (36.372619, 127.362159)
    ],
    // OV2 → OV3
    [
      (36.372619, 127.362159), (36.372125, 127.362176), (36.371873, 127.361729), (36.371621, 127.361282),
      (36.371178, 127.361896), (36.371071, 127.362054), (36.370928, 127.362337), (36.370819, 127.362587),
      (36.370778, 127.362796)
    ],
    // OV3 → OV4
    [
      (36.370778, 127.362796), (36.370707, 127.363144), (36.370697, 127.363481), (36.370724, 127.363839),
      (36.370809, 127.364202), (36.370865, 127.364391), (36.371055, 127.364753), (36.371116, 127.364892),
      (36.371150, 127.365027), (36.371138, 127.365219), (36.371024, 127.365375), (36.370953, 127.365433),
      (36.370291, 127.365970)
    ],
    // OV4 → OV5
    [
      (36.370291, 127.365970), (36.369915, 127.366278), (36.370058, 127.366560), (36.370802, 127.367964),
      (36.370466, 127.368473), (36.370088, 127.369044), (36.369676, 127.369391), (36.369521, 127.369450)
    ],
    // OV5 → OV6
    [
      (36.369521, 127.369450), (36.369319, 127.369474), (36.369124, 127.369399), (36.368993, 127.369299),
      (36.368878, 127.369182), (36.368801, 127.369075), (36.368714, 127.368874), (36.368675, 127.368761),
      (36.368664, 127.368656), (36.368702, 127.368271), (36.368737, 127.368148), (36.368969, 127.367950),
      (36.369123, 127.367819), (36.369133, 127.367781), (36.369112, 127.367709), (36.369035, 127.367557),
      (36.368831, 127.367157), (36.368656, 127.367274), (36.368521, 127.367333), (36.368347, 127.367373),
      (36.368196, 127.367366), (36.368039, 127.367327), (36.367892, 127.367257), (36.367726, 127.367102),
      (36.367581, 127.366852)
    ],
    // OV6 → OV7
    [
      (36.367581, 127.366852), (36.367411, 127.366534), (36.366910, 127.365570), (36.366562, 127.364946),
      (36.366488, 127.364785), (36.366438, 127.364658), (36.366409, 127.364505), (36.366381, 127.364016),
      (36.366344, 127.363837), (36.366255, 127.363621)
    ],
    // OV7 → OV8
    [
      (36.366255, 127.363621), (36.366190, 127.363480), (36.365982, 127.363180), (36.365866, 127.363059),
      (36.365568, 127.362851), (36.365444, 127.362711), (36.364929, 127.361724)
    ],
    // OV8 → OV9
    [
      (36.364929, 127.361724), (36.364735, 127.361360), (36.364363, 127.360707), (36.364059, 127.360443),
      (36.364003, 127.360371), (36.363884, 127.360139), (36.363524, 127.359433), (36.363863, 127.359167),
      (36.364275, 127.358799), (36.364631, 127.358565)
    ],
    // OV9 → OV10
    [
      (36.364631, 127.358565), (36.367318, 127.356808), (36.368122, 127.356282)
    ],
    // OV10 → OV11
    [
      (36.368122, 127.356282), (36.369320, 127.355510), (36.369492, 127.355378), (36.369727, 127.355263),
      (36.370146, 127.355227), (36.370997, 127.355230), (36.371284, 127.355247), (36.371418, 127.355293),
      (36.371461, 127.355348), (36.371474, 127.355408), (36.371469, 127.355637)
    ],
    // OV11 → OV1
    [
      (36.371469, 127.355637), (36.371456, 127.356194), (36.371479, 127.356502), (36.371585, 127.356919),
      (36.371677, 127.357047), (36.371783, 127.357142), (36.371974, 127.356867), (36.372195, 127.356628),
      (36.372774, 127.356348), (36.372938, 127.356297), (36.373191, 127.356261), (36.373341, 127.356259),
      (36.373396, 127.356278), (36.373466, 127.356323), (36.373460, 127.357583), (36.373453, 127.358923)
    ]
  ]
}
