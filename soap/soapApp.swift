//
//  soapApp.swift
//  soap
//
//  Created by Soongyu Kwon on 28/10/2024.
//

import SwiftUI
import SwiftyBeaver
import FirebaseCore

let logger = SwiftyBeaver.self

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct soapApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  init() {
    // Initialise Console Logger (SwiftyBeaver)
    let console = ConsoleDestination()
    console.format = "$DHH:mm:ss$d $L $M"
    console.logPrintWay = .logger(subsystem: "Main", category: "UI")
    logger.addDestination(console)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

