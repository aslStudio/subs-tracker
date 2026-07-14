import SwiftUI
import SwiftData

struct OverviewScreen: View {
    @Query
    private var subscriptions: [SubscriptionItem]

    private var categorySpendings: [CategorySpending] {
        Dictionary(grouping: subscriptions) { subscription in
            CategoryKey(
                id: subscription.category?.id.uuidString ?? CategoryKey.uncategorizedID,
                title: subscription.category?.title ?? "Без категории",
                color: subscription.category?.color ?? "#8E8E93"
            )
        }
        .map { key, subscriptions in
            CategorySpending(
                id: key.id,
                title: key.title,
                color: key.color,
                total: subscriptions.reduce(.zero) { $0 + $1.monthlyAmount },
                subscriptions: subscriptions.sorted {
                    $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
            )
        }
        .filter { $0.total > .zero }
        .sorted { $0.total > $1.total }
    }

    private var totalMonthlyAmount: Decimal {
        categorySpendings.reduce(.zero) { $0 + $1.total }
    }

    private var currentMonthPayments: [PaymentOccurrence] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: now),
            let lastDayOfMonth = calendar.date(
                byAdding: .day,
                value: -1,
                to: monthInterval.end
            )
        else {
            return []
        }

        return subscriptions
            .flatMap { subscription in
                subscription.paymentOccurrences(
                    from: today,
                    through: lastDayOfMonth,
                    calendar: calendar
                )
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                proportionsCard
                categoryDetailsCard
                currentMonthPaymentsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Статистика")
    }

    private var proportionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Расходы по категориям")
                    .font(.headline)

                Spacer()

                Text(totalMonthlyAmount.formattedUSD)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            if categorySpendings.isEmpty {
                emptyBlock(
                    title: "Нет данных",
                    subtitle: "Добавьте подписки, чтобы увидеть распределение"
                )
            } else {
                HStack(spacing: 18) {
                    ProportionRingChart(spendings: categorySpendings)
                        .frame(width: 150, height: 150)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(categorySpendings.prefix(5)) { spending in
                            legendRow(spending)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var categoryDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Категории")
                .font(.headline)

            if categorySpendings.isEmpty {
                emptyBlock(
                    title: "Категорий с расходами нет",
                    subtitle: "Создайте подписку и назначьте категорию"
                )
            } else {
                ForEach(categorySpendings) { spending in
                    DisclosureGroup {
                        VStack(spacing: 8) {
                            ForEach(spending.subscriptions) { subscription in
                                HStack(spacing: 10) {
                                    Text(subscription.title)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(subscription.monthlyAmount.formattedUSD)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: spending.color))
                                .frame(width: 10, height: 10)

                            Text(spending.title)
                                .font(.subheadline)

                            Spacer()

                            Text(spending.total.formattedUSD)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .tint(.primary)

                    if spending.id != categorySpendings.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private var currentMonthPaymentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ближайшие платежи в этом месяце")
                .font(.headline)

            if currentMonthPayments.isEmpty {
                emptyBlock(
                    title: "Платежей нет",
                    subtitle: "До конца месяца списаний не найдено"
                )
            } else {
                ForEach(currentMonthPayments) { payment in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(payment.subscription.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(payment.subscription.formattedAmount)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    if payment.id != currentMonthPayments.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func legendRow(_ spending: CategorySpending) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: spending.color))
                .frame(width: 8, height: 8)

            Text(spending.title)
                .font(.caption)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(spending.total.formattedUSD)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func emptyBlock(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private struct ProportionRingChart: View {
    let spendings: [CategorySpending]

    private var total: Double {
        spendings.reduce(0) { $0 + $1.total.doubleValue }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 22)

            ForEach(chartSegments) { segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(
                        Color(hex: segment.color),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(12)
    }

    private var chartSegments: [ChartSegment] {
        guard total > 0 else {
            return []
        }

        var start = 0.0

        return spendings.map { spending in
            let value = spending.total.doubleValue / total
            let segment = ChartSegment(
                id: spending.id,
                color: spending.color,
                start: start,
                end: start + value
            )

            start += value
            return segment
        }
    }
}

private struct ChartSegment: Identifiable {
    let id: String
    let color: String
    let start: Double
    let end: Double
}

private struct CategorySpending: Identifiable {
    let id: String
    let title: String
    let color: String
    let total: Decimal
    let subscriptions: [SubscriptionItem]
}

private struct PaymentOccurrence: Identifiable {
    let id: String
    let subscription: SubscriptionItem
    let date: Date
}

private struct CategoryKey: Hashable {
    static let uncategorizedID = "uncategorized"

    let id: String
    let title: String
    let color: String
}

private extension SubscriptionItem {
    func paymentOccurrences(
        from startDate: Date,
        through endDate: Date,
        calendar: Calendar
    ) -> [PaymentOccurrence] {
        var date = nextPaymentDate
        var occurrences: [PaymentOccurrence] = []

        while date <= endDate {
            if date >= startDate {
                occurrences.append(
                    PaymentOccurrence(
                        id: "\(id.uuidString)-\(date.timeIntervalSince1970)",
                        subscription: self,
                        date: date
                    )
                )
            }

            guard let nextDate = nextPaymentDate(after: date, calendar: calendar) else {
                break
            }

            date = nextDate
        }

        return occurrences
    }

    private func nextPaymentDate(after date: Date, calendar: Calendar) -> Date? {
        switch billingPeriod {
        case .weekly:
            calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            billingPeriod.nextPaymentDate(
                from: calendar.startOfDay(for: startPaymentData),
                relativeTo: calendar.date(byAdding: .day, value: 1, to: date) ?? date,
                calendar: calendar
            )
        case .three_monthly, .six_monthly, .yearly:
            nil
        }
    }
}

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    var formattedUSD: String {
        NumberFormatters.usd.string(from: NSDecimalNumber(decimal: self)) ?? "$0.00"
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

#Preview {
    NavigationStack {
        OverviewScreen()
    }
    .modelContainer(
        for: [
            SubscriptionItem.self,
            CategoryItem.self
        ],
        inMemory: true
    )
}
