import SwiftUI
import StoreKit

struct PremiumPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumAccess.self) private var premiumAccess

    @State private var selectedDuration: PremiumSubscriptionDuration = .yearly

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Full control over subscriptions")
                .font(.title2)
                .fontWeight(.bold)

            Text("Unlock advanced tools for managing your subscriptions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack {
                durationButton(.yearly)
                durationButton(.sixMonths)
                durationButton(.threeMonths)
                durationButton(.monthly)
            }
        }
    }

    private func durationButton(_ duration: PremiumSubscriptionDuration) -> some View {
        Button {
            selectedDuration = duration
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedDuration == duration ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedDuration == duration ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading) {
                    Text(duration.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if let description = duration.description {
                        Text(description)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let discount = duration.discount {
                        Text(discount)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }

                    Text(priceText(for: duration))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        selectedDuration == duration ? Color.accentColor : Color(.separator).opacity(0.25),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func priceText(for duration: PremiumSubscriptionDuration) -> String {
        if premiumAccess.isLoadingProducts {
            return "..."
        }

        return premiumAccess.product(for: duration.productID)?.displayPrice ?? "Unavailable"
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benefits")
                .font(.headline)

            PremiumBenefitRow(
                systemImage: "square.grid.2x2.fill",
                title: "Unlimited categories"
            )

            PremiumBenefitRow(
                systemImage: "creditcard.fill",
                title: "Unlimited subscriptions"
            )

            PremiumBenefitRow(
                systemImage: "icloud.fill",
                title: "Data sync with iCloud"
            )

            PremiumBenefitRow(
                systemImage: "bell.badge.fill",
                title: "Reminders before subscription payments"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var subscribeButton: some View {
        Button {
            Task {
                await premiumAccess.purchase(productID: selectedDuration.productID)

                if premiumAccess.isPremium {
                    dismiss()
                }
            }
        } label: {
            if premiumAccess.isPurchasing {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .controlSize(.small)
            } else {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
        }
        .disabled(
            premiumAccess.isLoadingProducts ||
            premiumAccess.isPurchasing ||
            premiumAccess.product(for: selectedDuration.productID) == nil
        )
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
    }

    private var restoreButton: some View {
        Button {
            Task {
                await premiumAccess.restorePurchases()

                if premiumAccess.isPremium {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.bordered)
        .disabled(premiumAccess.isPurchasing)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    durationPicker
                    benefits
                    subscribeButton
                    restoreButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await premiumAccess.loadProducts()
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { premiumAccess.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        premiumAccess.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                premiumAccess.errorMessage = nil
            }
        } message: {
            Text(premiumAccess.errorMessage ?? "")
        }
    }
}

private struct PremiumBenefitRow: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }
}

private enum PremiumSubscriptionDuration: CaseIterable {
    case monthly
    case threeMonths
    case sixMonths
    case yearly

    var title: String {
        switch self {
        case .monthly:
            "1 month"
        case .threeMonths:
            "3 months"
        case .sixMonths:
            "6 months"
        case .yearly:
            "12 months"
        }
    }
    
    var description: String? {
        switch self {
        case .monthly:
            nil
        case .threeMonths:
            "Good value"
        case .sixMonths:
            "Popular choice"
        case .yearly:
            "Best value"
        }
    }
    
    var discount: String? {
        switch self {
        case .monthly:
            nil
        case .threeMonths:
            nil
        case .sixMonths:
            nil
        case .yearly:
            "- 30%"
        }
    }

    var productID: String {
        switch self {
        case .monthly:
            "premium.month"
        case .threeMonths:
            "premium.3month"
        case .sixMonths:
            "premium.6month"
        case .yearly:
            "premium.year"
        }
    }
}

#Preview {
    PremiumPaywallSheet()
        .environment(PremiumAccess())
}
