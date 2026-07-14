import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case overview
    case subscriptions
    case categories
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumAccess.self) private var premiumAccess
    
    @State private var selectedTab: AppTab = .overview
    @State private var paywallRoute: PremiumPaywallRoute?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(
                "Overview",
                systemImage: "chart.pie.fill",
                value: .overview
            ) {
                screenContainer {
                    NavigationStack {
                        OverviewScreen()
                    }
                }
            }
            
            Tab(
                "Subscriptions",
                systemImage: "creditcard.fill",
                value: .subscriptions
            ) {
                screenContainer {
                    NavigationStack {
                        SubscriptionListScreen(paywallRoute: $paywallRoute)
                    }
                }
            }
            
            Tab(
                "Categories",
                systemImage: "square.grid.2x2.fill",
                value: .categories
            ) {
                screenContainer {
                    NavigationStack {
                        CategoryListScreen(paywallRoute: $paywallRoute)
                    }
                }
            }
        }
        .sheet(item: $paywallRoute) { _ in
            PremiumPaywallSheet()
        }
    }

    @ViewBuilder
    private func screenContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if premiumAccess.isPremium {
            content()
        } else {
            content()
                .safeAreaInset(edge: .bottom) {
                    PremiumBanner {
                        paywallRoute = .upgrade
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Color(.systemGroupedBackground))
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
        .environment(PremiumAccess())
}
