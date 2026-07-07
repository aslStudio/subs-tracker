enum BillingPeriod: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case three_monthly
    case six_monthly
    case yearly

    var id: String { rawValue }
}
