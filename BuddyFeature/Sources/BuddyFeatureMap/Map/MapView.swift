//
//  MapView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import SwiftUI
import BuddyDomain
import MapKit

struct CampusLocation: Hashable {
  let id = UUID()
  let name: String
  let latitude: Double
  let longitude: Double
  let category: LocationCategory

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

enum LocationCategory: Hashable {
  case building
  case academicBuilding
  case parking
  case cafe
  case gate
  case restaurant
  case cafeteria
  case dormitory
  case library
  case sportsField
  case hospital
  case olevStop
  case store

  var color: Color {
    switch self {
    case .building:
        .brown
    case .academicBuilding:
        .brown
    case .parking:
        .blue
    case .cafe:
        .orange
    case .gate:
        .gray
    case .restaurant:
        .orange
    case .cafeteria:
        .orange
    case .dormitory:
        .gray
    case .library:
        .brown
    case .sportsField:
        .green
    case .hospital:
        .red
    case .olevStop:
        .blue
    case .store:
        .yellow
    }
  }

  var symbol: String {
    switch self {
    case .building:
      "building.fill"
    case .academicBuilding:
      "graduationcap.fill"
    case .parking:
      "parkingsign"
    case .cafe:
      "cup.and.saucer.fill"
    case .gate:
      "door.left.hand.open"
    case .restaurant:
      "fork.knife"
    case .cafeteria:
      "fork.knife"
    case .dormitory:
      "bed.double.fill"
    case .library:
      "book.fill"
    case .sportsField:
      "sportscourt.fill"
    case .hospital:
      "cross.fill"
    case .olevStop:
      "bus.fill"
    case .store:
      "cart.fill"
    }
  }
}

struct MapView: View {
  @State private var position: MapCameraPosition = .region(
    MKCoordinateRegion(
      center: CLLocationCoordinate2D(
        latitude: 36.3725,
        longitude: 127.3624
      ),
      span: MKCoordinateSpan(
        latitudeDelta: 0.01,
        longitudeDelta: 0.01
      )
    )
  )

  @State private var locations: [CampusLocation] = [
    CampusLocation(
      name: "(E1) Main Gate",
      latitude: 36.365596,
      longitude: 127.363944,
      category: .gate
    ),
    CampusLocation(
      name: "(E2) Industrial Engineering & Management Building",
      latitude: 36.367364,
      longitude: 127.364392,
      category: .building
    ),
    CampusLocation(
      name: "(E2-2) Department of Industrial & Systems Engineering",
      latitude: 36.367423,
      longitude: 127.364022,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E3) Information & Electronics Building",
      latitude: 36.368002,
      longitude: 127.365033,
      category: .building
    ),
    CampusLocation(
      name: "(E3-1) School of Computing",
      latitude: 36.368075,
      longitude: 127.365819,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E3-2) School of Electrical Engineering",
      latitude: 36.368814,
      longitude: 127.365768,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E3-3) Device Innovation Facility",
      latitude: 36.368954,
      longitude: 127.366583,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E3-4) Saeneul Dong",
      latitude: 36.369295,
      longitude: 127.366283,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E3-5) KRAFTON Building",
      latitude: 36.367704,
      longitude: 127.36521,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E4) KAIST Institutes Building",
      latitude: 36.368218,
      longitude: 127.363864,
      category: .building
    ),
    CampusLocation(
      name: "(E5) Facility Club",
      latitude: 36.369263,
      longitude: 127.363563,
      category: .cafeteria
    ),
    CampusLocation(
      name: "(E6) Natural Science Building",
      latitude: 36.36993,
      longitude: 127.364599,
      category: .building
    ),
    CampusLocation(
      name: "(E6-1) Department of Mathematical Sciences",
      latitude: 36.369475,
      longitude: 127.36458,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E6-2) Department of Physics",
      latitude: 36.369865,
      longitude: 127.364177,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E6-3) Department of Biological Sciences",
      latitude: 36.369997,
      longitude: 127.365073,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E6-4) Department of Chemistry",
      latitude: 36.370451,
      longitude: 127.36443,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E6-5) GoongNi Laboratory Building",
      latitude: 36.370174,
      longitude: 127.363719,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E6-6) Basic Science Building",
      latitude: 36.370818,
      longitude: 127.365054,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E6-7) Educational Research Center of Biological Science",
      latitude: 36.369984,
      longitude: 127.365687,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E7) Biomedical Research Center",
      latitude: 36.370382,
      longitude: 127.365494,
      category: .building
    ),
    CampusLocation(
      name: "(E8) Sejong Hall",
      latitude: 36.37123,
      longitude: 127.367149,
      category: .dormitory
    ),
    CampusLocation(
      name: "(E9) Academic Cultural Complex",
      latitude: 36.369367,
      longitude: 127.362721,
      category: .library
    ),
    CampusLocation(
      name: "(E9-1) KAIST Art Museum",
      latitude: 36.369801,
      longitude: 127.362804,
      category: .building
    ),
    CampusLocation(
      name: "(E10) Storehouse",
      latitude: 36.37136,
      longitude: 127.365409,
      category: .building
    ),
    CampusLocation(
      name: "(E10-1) Applied Animal Research Center",
      latitude: 36.371643,
      longitude: 127.365446,
      category: .building
    ),
    CampusLocation(
      name: "(E11) Creative Learning Building",
      latitude: 36.370344,
      longitude: 127.362555,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E12) Energy Plant",
      latitude: 36.371276,
      longitude: 127.364513,
      category: .building
    ),
    CampusLocation(
      name: "(E13) Chung Mong-Hun Uribyeol Research Building",
      latitude: 36.372548,
      longitude: 127.366267,
      category: .building
    ),
    CampusLocation(
      name: "(E14) Main Administration Building",
      latitude: 36.370518,
      longitude: 127.361264,
      category: .building
    ),
    CampusLocation(
      name: "(E15) Auditorium",
      latitude: 36.372062,
      longitude: 127.362911,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E16) ChungMoonSoul Building",
      latitude: 36.371541,
      longitude: 127.361841,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E16-1) YANG Bun Soon Building",
      latitude: 36.371148,
      longitude: 127.362343,
      category: .academicBuilding
    ),
    CampusLocation(
      name: "(E17) Stadium",
      latitude: 36.369583,
      longitude: 127.368515,
      category: .sportsField
    ),
    CampusLocation(
      name: "(E18) Daejeon Disease-model Animal Center",
      latitude: 36.3683,
      longitude: 127.368126,
      category: .building
    ),
    CampusLocation(
      name: "(E18-1) Bio Model System Park",
      latitude: 36.368548,
      longitude: 127.368107,
      category: .building
    ),
    CampusLocation(
      name: "(E19) National Nano Fab Center",
      latitude: 36.368256,
      longitude: 127.366819,
      category: .building
    ),
    CampusLocation(
      name: "(E20) Kyeryong Hall",
      latitude: 36.372561,
      longitude: 127.367066,
      category: .building
    ),
    CampusLocation(
      name: "(E21) KAIST Clinic-Papalardo Center",
      latitude: 36.369386,
      longitude: 127.369829,
      category: .hospital
    ),
    CampusLocation(
      name: "(E22) Institute for Basic Science KAIST Campus",
      latitude: 36.369587,
      longitude: 127.367141,
      category: .building
    ),
    CampusLocation(
      name: "KAIST Brand Shop",
      latitude: 36.36974,
      longitude: 127.362238,
      category: .store
    ),
    CampusLocation(
      name: "Cafe Ogada",
      latitude: 36.36909,
      longitude: 127.362745,
      category: .cafe
    ),
    CampusLocation(
      name: "Caffè Pascucci",
      latitude: 36.368621,
      longitude: 127.364585,
      category: .cafe
    ),
    CampusLocation(
      name: "Grazie",
      latitude: 36.3682,
      longitude: 127.363571,
      category: .cafe
    ),
    CampusLocation(
      name: "SUBWAY",
      latitude: 36.371271,
      longitude: 127.362037,
      category: .restaurant
    ),
    CampusLocation(
      name: "California bakery&cafe",
      latitude: 36.370077,
      longitude: 127.363687,
      category: .cafe
    ),
    CampusLocation(
      name: "Convenience store",
      latitude: 36.369205,
      longitude: 127.36377,
      category: .store
    ),
    CampusLocation(
      name: "Convenience store",
      latitude: 36.371427,
      longitude: 127.366656,
      category: .store
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.367056,
      longitude: 127.366111,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.36671,
      longitude: 127.364346,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.366909,
      longitude: 127.365076,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.367509,
      longitude: 127.365918,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.367729,
      longitude: 127.36631,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.367691,
      longitude: 127.364604,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.368658,
      longitude: 127.366626,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.369894,
      longitude: 127.36919,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.369341,
      longitude: 127.365924,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.369483,
      longitude: 127.365505,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.370563,
      longitude: 127.367254,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.369721,
      longitude: 127.365451,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.370127,
      longitude: 127.365897,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.370563,
      longitude: 127.366079,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.370541,
      longitude: 127.365339,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.370978,
      longitude: 127.364271,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.370874,
      longitude: 127.363762,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.369958,
      longitude: 127.363166,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.369604,
      longitude: 127.363542,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.372306,
      longitude: 127.363724,
      category: .parking
    ),
    CampusLocation(
      name: "Parking",
      latitude: 36.3709,
      longitude: 127.360919,
      category: .parking
    ),
    CampusLocation(
      name: "East-Campus Cafeteria",
      latitude: 36.369021,
      longitude: 127.363794,
      category: .cafeteria
    )
  ]

  var body: some View {
    Map(position: $position) {
      UserAnnotation()

      ForEach(locations, id: \.id) { location in
        Marker(
          location.name,
          systemImage: location.category.symbol,
          coordinate: location.coordinate
        )
        .tint(location.category.color)
        .tag(location)
      }
    }
    .mapStyle(.standard(pointsOfInterest: .excludingAll))
    .mapControls {
      MapUserLocationButton()
    }
  }
}

#Preview {
  MapView()
}
