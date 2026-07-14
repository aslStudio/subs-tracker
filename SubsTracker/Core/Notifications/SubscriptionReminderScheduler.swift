import Foundation
import UserNotifications

enum SubscriptionReminderScheduler {
    private static let maxScheduledReminders = 24

    static func syncReminder(for subscription: SubscriptionItem, isPremium: Bool) async {
        await cancelReminders(for: subscription.id)

        guard isPremium, subscription.isReminderEnabled else {
            return
        }

        let isAuthorized = await requestAuthorization()
        guard isAuthorized else {
            return
        }

        let requests = reminderRequests(for: subscription)
        let center = UNUserNotificationCenter.current()

        for request in requests {
            do {
                try await center.add(request)
            } catch {
                continue
            }
        }
    }

    static func cancelReminders(for subscriptionID: UUID) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: reminderIdentifiers(for: subscriptionID)
        )
    }

    static func cancelAllReminders() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix("subscription-reminder-") }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        } catch {
            return false
        }
    }

    private static func reminderRequests(for subscription: SubscriptionItem) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        var paymentDate = subscription.nextPaymentDate
        var requests: [UNNotificationRequest] = []

        for index in 0..<maxScheduledReminders {
            guard
                let reminderDate = calendar.date(
                    byAdding: .day,
                    value: -subscription.reminderDaysBefore,
                    to: paymentDate
                )
            else {
                break
            }

            if reminderDate > .now {
                requests.append(
                    notificationRequest(
                        for: subscription,
                        paymentDate: paymentDate,
                        reminderDate: reminderDate,
                        index: index,
                        calendar: calendar
                    )
                )
            }

            guard let nextPaymentDate = subscription.billingPeriod.paymentDate(
                after: paymentDate,
                calendar: calendar
            ) else {
                break
            }

            paymentDate = nextPaymentDate
        }

        return requests
    }

    private static func notificationRequest(
        for subscription: SubscriptionItem,
        paymentDate: Date,
        reminderDate: Date,
        index: Int,
        calendar: Calendar
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Subscription Payment Soon"
        content.body = "\(subscription.title): \(subscription.formattedAmount) \(paymentDate.formatted(date: .abbreviated, time: .omitted))"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            ),
            repeats: false
        )

        return UNNotificationRequest(
            identifier: reminderIdentifier(for: subscription.id, index: index),
            content: content,
            trigger: trigger
        )
    }

    private static func reminderIdentifiers(for subscriptionID: UUID) -> [String] {
        (0..<maxScheduledReminders).map {
            reminderIdentifier(for: subscriptionID, index: $0)
        }
    }

    private static func reminderIdentifier(for subscriptionID: UUID, index: Int) -> String {
        "subscription-reminder-\(subscriptionID.uuidString)-\(index)"
    }
}

private extension BillingPeriod {
    func paymentDate(after date: Date, calendar: Calendar) -> Date? {
        switch self {
        case .weekly:
            calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            calendar.date(byAdding: .month, value: 1, to: date)
        case .three_monthly:
            calendar.date(byAdding: .month, value: 3, to: date)
        case .six_monthly:
            calendar.date(byAdding: .month, value: 6, to: date)
        case .yearly:
            calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}
