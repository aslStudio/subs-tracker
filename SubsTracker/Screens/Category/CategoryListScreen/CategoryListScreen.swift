import SwiftUI
import SwiftData

struct CategoryListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumAccess.self) private var premiumAccess

    @Query(sort: \CategoryItem.title)
    private var categories: [CategoryItem]

    @State private var categoryToEdit: CategoryItem?
    @State private var isShowingCreateCategory = false

    @Binding private var paywallRoute: PremiumPaywallRoute?

    init(paywallRoute: Binding<PremiumPaywallRoute?> = .constant(nil)) {
        _paywallRoute = paywallRoute
    }

    private func delete(_ category: CategoryItem) {
        modelContext.delete(category)
    }

    var body: some View {
        List {
            if categories.isEmpty {
                ContentUnavailableView(
                    "No Categories Yet",
                    systemImage: "square.grid.2x2",
                    description: Text("Add your first subscription category")
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
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                        .accessibilityLabel("Edit \(category.title)")
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(category)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete \(category.title)")
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
        .navigationDestination(isPresented: $isShowingCreateCategory) {
            CategoryCreateScreen()
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if premiumAccess.canCreateCategory(currentCount: categories.count) {
                        isShowingCreateCategory = true
                    } else {
                        paywallRoute = .upgrade
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Category")
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
    .environment(PremiumAccess())
}
