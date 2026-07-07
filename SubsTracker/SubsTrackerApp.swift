//
//  SubsTrackerApp.swift
//  SubsTracker
//
//  Created by Vlad Astahov on 07.07.2026.
//

import SwiftUI
import SwiftData

@main
struct SubsTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SubscriptionItem.self, inMemory: true)
    }
}
