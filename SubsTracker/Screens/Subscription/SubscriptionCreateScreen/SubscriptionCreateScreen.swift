import SwiftUI
import SwiftData

struct SubscriptionCreateScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

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
        let subscription = SubscriptionItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount.trimmingCharacters(in: .whitespacesAndNewlines),
            billingPeriod: billingPeriod,
            startPaymentData: startPaymentDate,
            category: category,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            isReminderEnabled: isReminderEnabled,
            reminderDaysBefore: reminderDaysBefore
        )

        modelContext.insert(subscription)
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
            .navigationTitle("Новая подписка")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
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
}
