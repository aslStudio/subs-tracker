import SwiftUI
import SwiftData

struct CategoryCreateScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var color: Color = Color.primary

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func save() {
        guard let selectedColor = color.hexString() else {
            return
        }
        
        let category = CategoryItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            color: selectedColor
        )

        modelContext.insert(category)
        dismiss()
    }

    var body: some View {
        NavigationStack {
            CategoryFormView(
                title: $title,
                color: $color
            )
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    CategoryCreateScreen()
        .modelContainer(
            for: [
                SubscriptionItem.self,
                CategoryItem.self
            ],
            inMemory: true
        )
}
