import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SubscriptionItem.self, inMemory: true)
        .modelContainer(for: CategoryItem.self, inMemory: true)
}
