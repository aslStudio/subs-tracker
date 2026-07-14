import Foundation

extension SubscriptionItem {
    var nextPaymentDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let firstPaymentDate = calendar.startOfDay(for: startPaymentData)

        guard firstPaymentDate < today else {
            return firstPaymentDate
        }

        return billingPeriod.nextPaymentDate(
            from: firstPaymentDate,
            relativeTo: today,
            calendar: calendar
        )
    }

    var amountSortValue: Decimal {
        amount.amountValue ?? .zero
    }

    var monthlyAmount: Decimal {
        billingPeriod.monthlyAmount(for: amount.amountValue ?? .zero)
    }

    var formattedAmount: String {
        guard let amountValue = amount.amountValue as NSDecimalNumber? else {
            return "$0.00"
        }

        return NumberFormatters.usd.string(from: amountValue) ?? "$\(amount)"
    }
}

extension BillingPeriod {
    func monthlyAmount(for amount: Decimal) -> Decimal {
        switch self {
        case .weekly:
            amount * Decimal(52) / Decimal(12)
        case .monthly:
            amount
        case .three_monthly:
            amount / Decimal(3)
        case .six_monthly:
            amount / Decimal(6)
        case .yearly:
            amount / Decimal(12)
        }
    }
}

extension BillingPeriod {
    func nextPaymentDate(
        from firstPaymentDate: Date,
        relativeTo today: Date,
        calendar: Calendar
    ) -> Date {
        switch self {
        case .weekly:
            let days = calendar.dateComponents(
                [.day],
                from: firstPaymentDate,
                to: today
            ).day ?? 0
            let periodsElapsed = days / 7
            let candidate = calendar.date(
                byAdding: .day,
                value: periodsElapsed * 7,
                to: firstPaymentDate
            ) ?? firstPaymentDate

            if candidate >= today {
                return candidate
            }

            return calendar.date(byAdding: .day, value: 7, to: candidate) ?? candidate

        case .monthly:
            return nextMonthlyPaymentDate(
                from: firstPaymentDate,
                relativeTo: today,
                monthInterval: 1,
                calendar: calendar
            )
        case .three_monthly:
            return nextMonthlyPaymentDate(
                from: firstPaymentDate,
                relativeTo: today,
                monthInterval: 3,
                calendar: calendar
            )
        case .six_monthly:
            return nextMonthlyPaymentDate(
                from: firstPaymentDate,
                relativeTo: today,
                monthInterval: 6,
                calendar: calendar
            )
        case .yearly:
            return nextMonthlyPaymentDate(
                from: firstPaymentDate,
                relativeTo: today,
                monthInterval: 12,
                calendar: calendar
            )
        }
    }

    private func nextMonthlyPaymentDate(
        from firstPaymentDate: Date,
        relativeTo today: Date,
        monthInterval: Int,
        calendar: Calendar
    ) -> Date {
        let elapsedMonths = calendar.dateComponents(
            [.month],
            from: firstPaymentDate,
            to: today
        ).month ?? 0
        let periodsElapsed = max(0, elapsedMonths / monthInterval)
        var candidate = paymentDate(
            from: firstPaymentDate,
            addingMonths: periodsElapsed * monthInterval,
            calendar: calendar
        )

        if candidate < today {
            candidate = paymentDate(
                from: firstPaymentDate,
                addingMonths: (periodsElapsed + 1) * monthInterval,
                calendar: calendar
            )
        }

        return candidate
    }

    private func paymentDate(
        from firstPaymentDate: Date,
        addingMonths months: Int,
        calendar: Calendar
    ) -> Date {
        let firstComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: firstPaymentDate
        )

        guard
            let firstMonth = calendar.date(
                from: DateComponents(
                    year: firstComponents.year,
                    month: firstComponents.month,
                    day: 1
                )
            ),
            let targetMonth = calendar.date(
                byAdding: .month,
                value: months,
                to: firstMonth
            ),
            let dayRange = calendar.range(of: .day, in: .month, for: targetMonth)
        else {
            return firstPaymentDate
        }

        let targetComponents = calendar.dateComponents(
            [.year, .month],
            from: targetMonth
        )
        let day = min(firstComponents.day ?? 1, dayRange.count)

        return calendar.date(
            from: DateComponents(
                year: targetComponents.year,
                month: targetComponents.month,
                day: day
            )
        ) ?? firstPaymentDate
    }
}

extension String {
    var amountValue: Decimal? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else {
            return nil
        }

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}

enum NumberFormatters {
    static let usd: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
