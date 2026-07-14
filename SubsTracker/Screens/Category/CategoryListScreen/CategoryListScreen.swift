import SwiftUI
import SwiftData

struct CategoryListScreen: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CategoryItem.title)
    private var categories: [CategoryItem]

    @State private var categoryToEdit: CategoryItem?

    private func delete(_ category: CategoryItem) {
        modelContext.delete(category)
    }

    var body: some View {
        List {
            if categories.isEmpty {
                ContentUnavailableView(
                    "Категорий пока нет",
                    systemImage: "square.grid.2x2",
                    description: Text("Добавьте первую категорию для подписок")
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .listRowInsets(
                    EdgeInsets(
                        top: 6,
                        leading: 16,
                        bottom: 6,
                        trailing: 16
                    )
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(categories) { category in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: category.color))
                            .frame(width: 14, height: 14)

                        Text(category.title)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .listRowInsets(
                        EdgeInsets(
                            top: 6,
                            leading: 16,
                            bottom: 6,
                            trailing: 16
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            categoryToEdit = category
                        } label: {
                            Label("Редактировать", systemImage: "pencil")
                        }
                        .tint(.blue)
                        .accessibilityLabel("Редактировать \(category.title)")
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(category)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        .accessibilityLabel("Удалить \(category.title)")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationDestination(
            isPresented: Binding(
                get: { categoryToEdit != nil },
                set: { isPresented in
                    if !isPresented {
                        categoryToEdit = nil
                    }
                }
            )
        ) {
            if let categoryToEdit {
                CategoryEditScreen(category: categoryToEdit)
            }
        }
        .navigationTitle("Категории")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CategoryCreateScreen()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Добавить категорию")
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryListScreen()
    }
    .modelContainer(
        for: [
            SubscriptionItem.self,
            CategoryItem.self
        ],
        inMemory: true
    )
}
