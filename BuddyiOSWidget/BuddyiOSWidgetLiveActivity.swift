////
////  BuddyiOSWidgetLiveActivity.swift
////  BuddyiOSWidget
////
////  Created by Soongyu Kwon on 25/12/2025.
////
//
//import ActivityKit
//import WidgetKit
//import SwiftUI
//
//struct BuddyiOSWidgetAttributes: ActivityAttributes {
//    public struct ContentState: Codable, Hashable {
//        // Dynamic stateful properties about your activity go here!
//        var emoji: String
//    }
//
//    // Fixed non-changing properties about your activity go here!
//    var name: String
//}
//
//struct BuddyiOSWidgetLiveActivity: Widget {
//    var body: some WidgetConfiguration {
//        ActivityConfiguration(for: BuddyiOSWidgetAttributes.self) { context in
//            // Lock screen/banner UI goes here
//            VStack {
//                Text("Hello \(context.state.emoji)")
//            }
//            .activityBackgroundTint(Color.cyan)
//            .activitySystemActionForegroundColor(Color.black)
//
//        } dynamicIsland: { context in
//            DynamicIsland {
//                // Expanded UI goes here.  Compose the expanded UI through
//                // various regions, like leading/trailing/center/bottom
//                DynamicIslandExpandedRegion(.leading) {
//                    Text("Leading")
//                }
//                DynamicIslandExpandedRegion(.trailing) {
//                    Text("Trailing")
//                }
//                DynamicIslandExpandedRegion(.bottom) {
//                    Text("Bottom \(context.state.emoji)")
//                    // more content
//                }
//            } compactLeading: {
//                Text("L")
//            } compactTrailing: {
//                Text("T \(context.state.emoji)")
//            } minimal: {
//                Text(context.state.emoji)
//            }
//            .widgetURL(URL(string: "http://www.apple.com"))
//            .keylineTint(Color.red)
//        }
//    }
//}
//
//extension BuddyiOSWidgetAttributes {
//    fileprivate static var preview: BuddyiOSWidgetAttributes {
//        BuddyiOSWidgetAttributes(name: "World")
//    }
//}
//
//extension BuddyiOSWidgetAttributes.ContentState {
//    fileprivate static var smiley: BuddyiOSWidgetAttributes.ContentState {
//        BuddyiOSWidgetAttributes.ContentState(emoji: "😀")
//     }
//     
//     fileprivate static var starEyes: BuddyiOSWidgetAttributes.ContentState {
//         BuddyiOSWidgetAttributes.ContentState(emoji: "🤩")
//     }
//}
//
//#Preview("Notification", as: .content, using: BuddyiOSWidgetAttributes.preview) {
//   BuddyiOSWidgetLiveActivity()
//} contentStates: {
//    BuddyiOSWidgetAttributes.ContentState.smiley
//    BuddyiOSWidgetAttributes.ContentState.starEyes
//}
