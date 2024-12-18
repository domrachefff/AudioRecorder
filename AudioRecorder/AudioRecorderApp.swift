//
//  AudioRecorderApp.swift
//  AudioRecorder
//
//  Created by Алексей on 13.12.2024.
//

import SwiftUI

@main
struct AudioRecorderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
