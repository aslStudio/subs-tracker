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
    @State private var premiumAccess = PremiumAccess()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(premiumAccess)
                .task {
                    await premiumAccess.start()
                }
        }
        .modelContainer(
            for: [
                SubscriptionItem.self,
                CategoryItem.self
            ],
        )
    }
}
