//
//  AZTrackerApp.swift
//  AZTracker
//
//  Created by Ahmed Zahran on 4/6/25.
//

import SwiftUI

@main
struct AZTrackerApp: App {
    let persistenceController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
