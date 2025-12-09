//
//  PhotoCleanerApp.swift
//  PhotoCleaner
//
//  Created by Daniil Mukashev on 2025-12-09.
//

import SwiftUI
import CoreData

@main
struct PhotoCleanerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
