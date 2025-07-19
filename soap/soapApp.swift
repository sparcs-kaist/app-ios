//
//  soapApp.swift
//  soap
//
//  Created by Soongyu Kwon on 28/10/2024.
//

import SwiftUI
import SwiftyBeaver
let logger = SwiftyBeaver.self

@main
struct soapApp: App {
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

