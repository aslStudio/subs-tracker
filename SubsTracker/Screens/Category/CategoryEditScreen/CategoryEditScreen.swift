import SwiftUI
import SwiftData

struct CategoryEditScreen: View {
    @Environment(\.dismiss) private var dismiss

    let category: CategoryItem
    
    @State private var title = ""
    @State private var color: Color = Color.primary

    init(category: CategoryItem) {
        self.category = category
        
        _title = State(initialValue: category.title)
        _color = State(
            initialValue: Color(hex: category.color)
        )
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func save() {
        guard let selectedColor = color.hexString() else {
            return
        }

        category.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        category.color = selectedColor
        dismiss()
    }

    var body: some View {
        CategoryFormView(
            title: $title,
            color: $color
        )
        .navigationTitle("Edit")
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

#Preview {
    NavigationStack {
        CategoryEditScreen(
            category: CategoryItem(
                title: "Title",
                color: Color.blue.hexString() ?? ""
            )
        )
    }
    .modelContainer(
        for: [
            SubscriptionItem.self,
            CategoryItem.self
        ],
        inMemory: true
    )
}
