import SwiftUI
import SwiftData

struct SubscriptionForm: View {
    @Query
    private var categories: [CategoryItem]
    
    @Binding var title: String
    @Binding var amount: String
    @Binding var billingPeriod: BillingPeriod
    @Binding var startPaymentDate: Date
    @Binding var category: CategoryItem?
    @Binding var note: String
    @Binding var isReminderEnabled: Bool
    @Binding var reminderDaysBefore: Int

    private var amountBinding: Binding<String> {
        Binding(
            get: { amount },
            set: { amount = $0.currencyAmountInput }
        )
    }
    
    var body: some View {
        Form {
            Section("Подписка") {
                TextField("Название", text: $title)

                TextField("Стоимость, $", text: amountBinding)
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

                Picker(
                    selection: $category
                ) {
                    Text("Без категории")
                        .tag(nil as CategoryItem?)

                    ForEach(categories) { item in
                        HStack {
                            Text(item.title)
                        }
                        .tag(item as CategoryItem?)
                    }
                } label: {
                    Text("Категория")
                }
                
                NavigationLink {
                    CategoryCreateScreen()
                } label: {
                    Text("Создать категорию")
                        .foregroundColor(.accentColor)
                }
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

private extension String {
    var currencyAmountInput: String {
        var result = ""
        var hasSeparator = false

        for character in self {
            if character.isNumber {
                result.append(character)
            } else if character == "." || character == "," {
                guard !hasSeparator else {
                    continue
                }

                result.append(".")
                hasSeparator = true
            }
        }

        return result
    }
}
