import SwiftUI
import SwiftData

struct SubscriptionCreateScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumAccess.self) private var premiumAccess

    @Query
    private var categories: [CategoryItem]
    
    @State private var title = ""
    @State private var amount = ""
    @State private var billingPeriod: BillingPeriod = .monthly
    @State private var startPaymentDate = Date()
    @State private var category: CategoryItem? = nil
    @State private var note = ""
    @State private var isReminderEnabled = true
    @State private var reminderDaysBefore = 1

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveSubscription() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldEnableReminder = premiumAccess.isPremium && isReminderEnabled
        let subscription = SubscriptionItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount.trimmingCharacters(in: .whitespacesAndNewlines),
            billingPeriod: billingPeriod,
            startPaymentData: startPaymentDate,
            category: category,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            isReminderEnabled: shouldEnableReminder,
            reminderDaysBefore: reminderDaysBefore
        )

        modelContext.insert(subscription)
        Task {
            await SubscriptionReminderScheduler.syncReminder(
                for: subscription,
                isPremium: premiumAccess.isPremium
            )
        }
        dismiss()
    }

    var body: some View {
        NavigationStack {
            SubscriptionForm(
                title: $title,
                amount: $amount,
                billingPeriod: $billingPeriod,
                startPaymentDate: $startPaymentDate,
                category: $category,
                note: $note,
                isReminderEnabled: $isReminderEnabled,
                reminderDaysBefore: $reminderDaysBefore
            )
            .navigationTitle("New Subscription")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSubscription()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    SubscriptionCreateScreen()
        .modelContainer(
            for: [
                SubscriptionItem.self,
                CategoryItem.self
            ],
            inMemory: true
        )
        .environment(PremiumAccess())
}
