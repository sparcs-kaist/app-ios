//
//  HomeView.swift
//  soap
//
//  Created by Soongyu Kwon on 28/10/2024.
//

import SwiftUI

struct HomeViewOld: View {
    private var appSettings: AppSettings = .init()
    private let title: String = "Ara"
    
    var body: some View {
        GeometryReader { outer in
            NavigationStack {
                ListView(title: title, outer: outer, appSettings: appSettings)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            ToolbarTitle(title: title, appSettings: appSettings)
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 4) {
                                ToolbarNotificationsButton(appSettings: appSettings)
                                
                                ToolbarSearchButton(appSettings: appSettings)
                            }
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct ListView: View {
    let title: String
    let outer: GeometryProxy
    let appSettings: AppSettings
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView() {
                LazyVStack {
                    HeaderView(title: title, outer: outer, appSettings: appSettings)
                        .padding(.horizontal)
                    VStack(spacing: 20) {
                        SuggestionsRow()
                        
                        GeneralBoardRow()
                        
                        TaxiBoardRow()
                        
                        MessagesToTheSchoolBoardRow()
                        
                        ZaboBoardRow()
                        
                        NoticeBoardRow()
                        
                        BoardsRow()
                        
                        TradeBoardRow()
                        
                        ReviewsRow()
                        
                        Image("sparcs")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                            .padding()
                    }
                }
                .scrollTargetLayout()
                .frame(maxWidth: .infinity)
            }.scrollTargetBehavior(.viewAligned)
                .background(Color(uiColor: .secondarySystemBackground))
        }
    }
}

struct HeaderView: View {
    let title: String
    let outer: GeometryProxy
    let appSettings: AppSettings
    
    @State private var showsTaxiPreviewView: Bool = false
    @State private var roomInfo: RoomInfo = .mock

    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .textCase(nil)
            Spacer()
            Button(action: {
                // notifications
                showsTaxiPreviewView.toggle()
            }, label: {
                Image(systemName: "bell")
                    .font(.footnote)
                    .frame(width: 18, height: 18)
                    .padding(4)
                    .background(.ultraThinMaterial, in: .circle)
            })
            .padding(.trailing, 4)
            Button(action: {
                // search
            }, label: {
                Image(systemName: "magnifyingglass")
                    .font(.footnote)
                    .frame(width: 18, height: 18)
                    .padding(4)
                    .background(.ultraThinMaterial, in: .circle)
            })
        }
        .foregroundStyle(.primary)
        .background { appSettings.scrollDetector(topInsets: outer.safeAreaInsets.top) }
//        .sheet(isPresented: $showsTaxiPreviewView, content: {
//            TaxiPreviewView(roomInfo: $roomInfo)
//                .presentationDetents([.height(320), .medium])
//                .presentationDragIndicator(.visible)
//        })
    }
}

struct ToolbarTitle: View {
  let title: String
  let appSettings: AppSettings
  
  var body: some View {
    Text(title)
      .font(.headline)
      .fontWeight(.bold)
      .foregroundStyle(.primary)
      .opacity(appSettings.showingScrolledTitle ? 1 : 0)
      .animation(.easeInOut, value: appSettings.showingScrolledTitle)
  }
}

struct ToolbarSearchButton: View {
    let appSettings: AppSettings
    
    var body: some View {
        Button(action: {
            // search
        }, label: {
            Image(systemName: "magnifyingglass")
                .font(.caption2)
                .frame(width: 18, height: 18)
                .padding(4)
                .background(.ultraThinMaterial, in: .circle)
        })
            .foregroundStyle(.primary)
            .opacity(appSettings.showingScrolledTitle ? 1 : 0)
            .animation(.easeInOut, value: appSettings.showingScrolledTitle)
    }
}

struct ToolbarNotificationsButton: View {
    let appSettings: AppSettings
    
    var body: some View {
        Button(action: {
            // notifications
        }, label: {
            Image(systemName: "bell")
                .font(.caption2)
                .frame(width: 18, height: 18)
                .padding(4)
                .background(.ultraThinMaterial, in: .circle)
        })
            .foregroundStyle(.primary)
            .opacity(appSettings.showingScrolledTitle ? 1 : 0)
            .animation(.easeInOut, value: appSettings.showingScrolledTitle)
    }
}

@Observable
final class AppSettings {
  var showingScrolledTitle = false
  func scrollDetector(topInsets: CGFloat) -> some View {
    GeometryReader { proxy in
      let minY = proxy.frame(in: .global).minY
      let isUnderToolbar = minY - topInsets < 0
      Color.clear.onChange(of: isUnderToolbar) { _, newVal in
        self.showingScrolledTitle = newVal
      }
    }
  }
}

#Preview {
    HomeViewOld()
}

struct SuggestionsRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                NextLectureSuggestionView()
                NextTaxiSuggestionView(roomInfo: RoomInfo.mock)
            }
            .padding(.horizontal)
            .scrollTargetLayout()
        }.scrollTargetBehavior(.viewAligned)
    }
}

struct NextLectureSuggestionView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Label(title: {
                Text("System Programming")
            }, icon: {
                Image(systemName: "rectangle.stack.fill")
            })
            .fontWeight(.medium)
            .font(.subheadline)
            .foregroundStyle(.white)
        
            Text("in 2 hours")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(.red.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct NextTaxiSuggestionView: View {
    let roomInfo: RoomInfo

    var body: some View {
        VStack(alignment: .leading) {
            Label(title: {
                Text(roomInfo.origin.title)
                Image(systemName: "arrow.right")
                Text(roomInfo.destination.title)
            }, icon: {
                Image(systemName: "car.2.fill")
            })
            .fontWeight(.medium)
            .font(.subheadline)
            .foregroundStyle(.white)

            Text(roomInfo.departureTime.relativeTimeString)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(.purple)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GeneralBoardRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("General")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<3) { _ in
                    VStack(alignment: .leading) {
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
                            .lineLimit(1)
                        Text("Lorem ipsum\t13 min ago")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }.padding(.horizontal)
    }
}

struct TaxiBoardRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Taxi")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(RoomInfo.mockList, id: \.name) { room in
                        VStack(alignment: .leading) {
                            HStack {
                                HStack {
                                    Text(room.origin.title)
                                    Image(systemName: "arrow.right")
                                    Text(room.destination.title)
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Text("\(room.occupancy)/\(room.capacity)")
                                    Image(systemName: "person.2")
                                }
                                .font(.footnote)
                                .foregroundStyle(.green)
                                .padding(4)
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }

                            Text(room.departureTime.relativeTimeString + "\tLorem ipsum")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: .screenWidth - 80)
                        .padding()
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                        .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                            effect
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }.scrollTargetBehavior(.viewAligned)
        }
    }
}

struct MessagesToTheSchoolBoardRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Messages to the School")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(0..<3) { _ in
                        VStack(alignment: .leading) {
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
                                .lineLimit(1)
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                    Text("Answered")
                                }
                                .foregroundStyle(.green)
                                .padding(4)
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text("Lorem ipsum\t13 min ago")
                                    .foregroundStyle(.secondary)
                            }.font(.footnote)
                        }
                        .frame(width: .screenWidth - 80)
                        .padding()
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                        .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                            effect
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }.scrollTargetBehavior(.viewAligned)
        }
    }
}

struct NoticeBoardRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Notice")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<3) { _ in
                    VStack(alignment: .leading) {
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
                            .lineLimit(1)
                        Text("Lorem ipsum\t13 min ago")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }.padding(.horizontal)
    }
}

struct BoardsRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Boards")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<7) { _ in
                    HStack(alignment: .bottom, spacing: 16) {
                        Text("Board")
                            .fontWeight(.medium)
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }.padding(.horizontal)
    }
}

struct ZaboBoardRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Zabo")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(0..<8) { _ in
                        Image("zabo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .screenWidth - 80, maxHeight: 200)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )
                            .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                                effect
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }.scrollTargetBehavior(.viewAligned)
        }
    }
}

struct TradeBoardRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Trade")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(0..<8) { i in
                        VStack(alignment: .leading) {
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
                                .lineLimit(1)
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "basket")
                                    Text((i % 2 == 0) ? "Sell" : "Buy")
                                }
                                    .foregroundStyle((i % 2 == 0) ? .blue : .red)
                                    .padding(4)
                                    .background((i % 2 == 0) ? .blue.opacity(0.1) : .red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                Text("Lorem ipsum\t13 min ago")
                                    .foregroundStyle(.secondary)
                            }.font(.footnote)
                        }
                        .frame(width: .screenWidth - 80)
                        .padding()
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                        .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                            effect
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }.scrollTargetBehavior(.viewAligned)
        }
    }
}

struct ReviewsRow: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Text("Reviews")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .font(.headline)
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(0..<7) { _ in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .bottom) {
                                Text("System Programming")
                                    .fontWeight(.medium)
                                Text("2024 Jongse Park")
                                    .font(.subheadline)
                            }
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
                                .lineLimit(2)
                            Text("Grade A    Load A    Speech A")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: .screenWidth - 80)
                        .padding()
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                        .scrollTransition(.interactive, axis: .horizontal) { effect, phase in
                            effect
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .scrollTargetLayout()
            }.scrollTargetBehavior(.viewAligned)
        }
    }
}
