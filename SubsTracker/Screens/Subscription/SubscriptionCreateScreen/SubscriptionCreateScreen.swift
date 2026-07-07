import SwiftUI
import SwiftData

struct SubscriptionCreateScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var amount = ""
    @State private var billingPeriod: BillingPeriod = .monthly
    @State private var startPaymentDate = Date()
    @State private var category = ""
    @State private var note = ""
    @State private var isReminderEnabled = true
    @State private var reminderDaysBefore = 1

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Подписка") {
                    TextField("Название", text: $title)

                    TextField("Стоимость", text: $amount)
                        .amountKeyboard()

                    Picker("Период оплаты", selection: $billingPeriod) {
                        ForEach(BillingPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                }

                Section("Платеж") {
                    DatePicker(
                        "Первый платеж",
                        selection: $startPaymentDate,
                        displayedComponents: .date
                    )

                    TextField("Категория", text: $category)
                }

                Section("Напоминание") {
                    Toggle("Включить напоминание", isOn: $isReminderEnabled)

                    if isReminderEnabled {
                        Stepper(
                            "За \(reminderDaysBefore) \(reminderDaysBefore.daysTitle) до оплаты",
                            value: $reminderDaysBefore,
                            in: 1...30
                        )
                    }
                }

                Section("Заметка") {
                    TextEditor(text: $note)
                        .frame(minHeight: 96)
                }
            }
            .navigationTitle("Новая подписка")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveSubscription()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveSubscription() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let subscription = SubscriptionItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount.trimmingCharacters(in: .whitespacesAndNewlines),
            billingPeriod: billingPeriod,
            startPaymentData: startPaymentDate,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            isReminderEnabled: isReminderEnabled,
            reminderDaysBefore: reminderDaysBefore
        )

        modelContext.insert(subscription)
        dismiss()
    }
}

private extension BillingPeriod {
    var title: String {
        switch self {
        case .weekly:
            "Еженедельно"
        case .monthly:
            "Ежемесячно"
        case .three_monthly:
            "Раз в 3 месяца"
        case .six_monthly:
            "Раз в 6 месяцев"
        case .yearly:
            "Ежегодно"
        }
    }
}

private extension Int {
    var daysTitle: String {
        let lastTwoDigits = self % 100
        let lastDigit = self % 10

        if (11...14).contains(lastTwoDigits) {
            return "дней"
        }

        switch lastDigit {
        case 1:
            return "день"
        case 2...4:
            return "дня"
        default:
            return "дней"
        }
    }
}

private extension View {
    @ViewBuilder
    func amountKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}

#Preview {
    SubscriptionCreateScreen()
        .modelContainer(for: SubscriptionItem.self, inMemory: true)
}
