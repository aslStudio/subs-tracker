import SwiftUI
import SwiftData

struct SubscriptionListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumAccess.self) private var premiumAccess

    @Query
    private var subscriptions: [SubscriptionItem]

    @Query(sort: \CategoryItem.title)
    private var categories: [CategoryItem]

    @State private var selectedCategoryID = CategoryFilterID.all
    @State private var sortOption: SubscriptionSortOption = .nextPaymentAscending
    @State private var subscriptionToEdit: SubscriptionItem?
    @State private var isShowingCreateSubscription = false

    @Binding private var paywallRoute: PremiumPaywallRoute?

    init(paywallRoute: Binding<PremiumPaywallRoute?> = .constant(nil)) {
        _paywallRoute = paywallRoute
    }

    private var filteredSubscriptions: [SubscriptionItem] {
        return subscriptions
            .filter { subscription in
                if selectedCategoryID == CategoryFilterID.none {
                    return subscription.category == nil
                }

                if selectedCategoryID != CategoryFilterID.all &&
                    subscription.category?.id.uuidString != selectedCategoryID {
                    return false
                }

                return true
            }
            .sorted(using: sortOption)
    }

    private var selectedCategoryTitle: String {
        if selectedCategoryID == CategoryFilterID.all {
            return "All Categories"
        }

        if selectedCategoryID == CategoryFilterID.none {
            return "Uncategorized"
        }

        return categories.first { $0.id.uuidString == selectedCategoryID }?.title ?? "Category"
    }

    private func delete(_ subscription: SubscriptionItem) {
        let subscriptionID = subscription.id
        modelContext.delete(subscription)
        Task {
            await SubscriptionReminderScheduler.cancelReminders(for: subscriptionID)
        }
    }

    var body: some View {
        List {
            filtersView

            if filteredSubscriptions.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredSubscriptions) { subscription in
                    subscriptionRow(subscription)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationDestination(
            isPresented: Binding(
                get: { subscriptionToEdit != nil },
                set: { isPresented in
                    if !isPresented {
                        subscriptionToEdit = nil
                    }
                }
            )
        ) {
            if let subscriptionToEdit {
                SubscriptionEditScreen(subscription: subscriptionToEdit)
            }
        }
        .navigationDestination(isPresented: $isShowingCreateSubscription) {
            SubscriptionCreateScreen()
        }
        .navigationTitle("Subscriptions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if premiumAccess.canCreateSubscription(currentCount: subscriptions.count) {
                        isShowingCreateSubscription = true
                    } else {
                        paywallRoute = .upgrade
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Subscription")
            }
        }
    }

    private var filtersView: some View {
        HStack(spacing: 12) {
            Menu {
                Button("All Categories") {
                    selectedCategoryID = CategoryFilterID.all
                }

                Button("Uncategorized") {
                    selectedCategoryID = CategoryFilterID.none
                }

                ForEach(categories) { category in
                    Button(category.title) {
                        selectedCategoryID = category.id.uuidString
                    }
                }
            } label: {
                filterBlock(
                    title: "Category",
                    value: selectedCategoryTitle,
                    systemImage: "square.grid.2x2"
                )
            }
            .frame(maxWidth: .infinity)

            Menu {
                ForEach(SubscriptionSortOption.allCases) { option in
                    Button(option.title) {
                        sortOption = option
                    }
                }
            } label: {
                filterBlock(
                    title: "Sort",
                    value: sortOption.title,
                    systemImage: "arrow.up.arrow.down"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .listRowInsets(cardInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func filterBlock(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .tint(.primary)
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Subscriptions Yet",
            systemImage: "creditcard",
            description: Text("Add your first subscription")
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .listRowInsets(cardInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func subscriptionRow(_ subscription: SubscriptionItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(subscription.title)
                    .font(.headline)

                Spacer()

                Text(subscription.formattedAmount)
                    .font(.headline)
            }

            HStack(spacing: 8) {
                Label("Next Payment", systemImage: "calendar")

                Text(subscription.nextPaymentDate.formatted(date: .abbreviated, time: .omitted))

                Spacer(minLength: 12)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            categoryView(subscription.category)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .listRowInsets(cardInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                subscriptionToEdit = subscription
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
            .accessibilityLabel("Edit \(subscription.title)")
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                delete(subscription)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete \(subscription.title)")
        }
    }

    private func categoryView(_ category: CategoryItem?) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: category?.color ?? "#8E8E93"))
                .frame(width: 8, height: 8)

            Text(category?.title ?? "Uncategorized")
                .lineLimit(1)
        }
    }

    private var cardInsets: EdgeInsets {
        EdgeInsets(
            top: 6,
            leading: 16,
            bottom: 6,
            trailing: 16
        )
    }
}

private enum SubscriptionSortOption: String, CaseIterable, Identifiable {
    case nextPaymentAscending
    case nextPaymentDescending
    case amountAscending
    case amountDescending
    case titleAscending
    case titleDescending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nextPaymentAscending:
            "Next Payment ↑"
        case .nextPaymentDescending:
            "Next Payment ↓"
        case .amountAscending:
            "Cost ↑"
        case .amountDescending:
            "Cost ↓"
        case .titleAscending:
            "Name ↑"
        case .titleDescending:
            "Name ↓"
        }
    }
}

private enum CategoryFilterID {
    static let all = "all"
    static let none = "none"
}

private extension Array where Element == SubscriptionItem {
    func sorted(using option: SubscriptionSortOption) -> [SubscriptionItem] {
        sorted { first, second in
            switch option {
            case .nextPaymentAscending:
                first.nextPaymentDate < second.nextPaymentDate
            case .nextPaymentDescending:
                first.nextPaymentDate > second.nextPaymentDate
            case .amountAscending:
                first.amountSortValue < second.amountSortValue
            case .amountDescending:
                first.amountSortValue > second.amountSortValue
            case .titleAscending:
                first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            case .titleDescending:
                first.title.localizedCaseInsensitiveCompare(second.title) == .orderedDescending
            }
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionListScreen()
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
