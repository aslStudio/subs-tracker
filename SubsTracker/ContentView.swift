import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case overview
    case subscriptions
    case categories
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: AppTab = .overview

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(
                "Статистика",
                systemImage: "chart.pie.fill",
                value: .overview
            ) {
                NavigationStack {
                    OverviewScreen()
                }
            }
            
            Tab(
                "Подписки",
                systemImage: "creditcard.fill",
                value: .subscriptions
            ) {
                NavigationStack {
                    SubscriptionListScreen()
                }
            }
            
            Tab(
                "Категории",
                systemImage: "square.grid.2x2.fill",
                value: .categories
            ) {
                NavigationStack {
                    CategoryListScreen()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                SubscriptionItem.self,
                CategoryItem.self
            ],
            inMemory: true
        )
}
