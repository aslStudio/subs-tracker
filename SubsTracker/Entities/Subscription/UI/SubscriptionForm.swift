import SwiftUI
import SwiftData

struct SubscriptionForm: View {
    @Environment(PremiumAccess.self) private var premiumAccess

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
            Section("Subscription") {
                TextField("Name", text: $title)

                TextField("Cost, $", text: amountBinding)
                    .amountKeyboard()

                Picker("Billing Period", selection: $billingPeriod) {
                    ForEach(BillingPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
            }

            Section("Payment") {
                DatePicker(
                    "First Payment",
                    selection: $startPaymentDate,
                    displayedComponents: .date
                )

                Picker(
                    selection: $category
                ) {
                    Text("Uncategorized")
                        .tag(nil as CategoryItem?)

                    ForEach(categories) { item in
                        HStack {
                            Text(item.title)
                        }
                        .tag(item as CategoryItem?)
                    }
                } label: {
                    Text("Category")
                }
                
                NavigationLink {
                    CategoryCreateScreen()
                } label: {
                    Text("Create Category")
                        .foregroundColor(.accentColor)
                }
            }

            if premiumAccess.isPremium {
                Section("Reminder") {
                Toggle("Enable Reminder", isOn: $isReminderEnabled)

                    if isReminderEnabled {
                        Stepper(
                            "\(reminderDaysBefore) \(reminderDaysBefore.daysTitle) before payment",
                            value: $reminderDaysBefore,
                            in: 1...30
                        )
                    }
                }
            }

            Section("Note") {
                TextEditor(text: $note)
                    .frame(minHeight: 96)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 96)
        }
    }
}

private extension BillingPeriod {
    var title: String {
        switch self {
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        case .three_monthly:
            "Every 3 Months"
        case .six_monthly:
            "Every 6 Months"
        case .yearly:
            "Yearly"
        }
    }
}

private extension Int {
    var daysTitle: String {
        let lastTwoDigits = self % 100
        let lastDigit = self % 10

        if (11...14).contains(lastTwoDigits) {
            return "days"
        }

        switch lastDigit {
        case 1:
            return "day"
        case 2...4:
            return "days"
        default:
            return "days"
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
