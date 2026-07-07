import Foundation
import SwiftData

@Model
final class SubscriptionItem {
    var id: UUID
    var title: String
    var amount: String
    var billingPeriod: BillingPeriod
    var startPaymentData: Date
    var category: String
    var note: String?
    var isReminderEnabled: Bool
    var reminderDaysBefore: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        amount: String,
        billingPeriod: BillingPeriod,
        startPaymentData: Date,
        category: String,
        note: String? = nil,
        isReminderEnabled: Bool = true,
        reminderDaysBefore: Int = 1,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.billingPeriod = billingPeriod
        self.startPaymentData = startPaymentData
        self.category = category
        self.note = note
        self.isReminderEnabled = isReminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
