import SwiftUI
import SwiftData

struct SubscriptionEditScreen: View {
    @Environment(\.dismiss) private var dismiss

    let subscription: SubscriptionItem

    @State private var title = ""
    @State private var amount = ""
    @State private var billingPeriod: BillingPeriod = .monthly
    @State private var startPaymentDate = Date()
    @State private var category: CategoryItem?
    @State private var note = ""
    @State private var isReminderEnabled = true
    @State private var reminderDaysBefore = 1

    init(subscription: SubscriptionItem) {
        self.subscription = subscription

        _title = State(initialValue: subscription.title)
        _amount = State(initialValue: subscription.amount)
        _billingPeriod = State(initialValue: subscription.billingPeriod)
        _startPaymentDate = State(initialValue: subscription.startPaymentData)
        _category = State(initialValue: subscription.category)
        _note = State(initialValue: subscription.note ?? "")
        _isReminderEnabled = State(initialValue: subscription.isReminderEnabled)
        _reminderDaysBefore = State(initialValue: subscription.reminderDaysBefore)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        subscription.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        subscription.amount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        subscription.billingPeriod = billingPeriod
        subscription.startPaymentData = startPaymentDate
        subscription.category = category
        subscription.note = trimmedNote.isEmpty ? nil : trimmedNote
        subscription.isReminderEnabled = isReminderEnabled
        subscription.reminderDaysBefore = reminderDaysBefore
        subscription.updatedAt = .now

        dismiss()
    }

    var body: some View {
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
        .navigationTitle("Редактирование")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    save()
                }
                .disabled(!canSave)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionEditScreen(
            subscription: SubscriptionItem(
                title: "Netflix",
                amount: "9.99",
                billingPeriod: .monthly,
                startPaymentData: .now,
                category: CategoryItem(
                    title: "Развлечения",
                    color: "#FF3B30"
                )
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
