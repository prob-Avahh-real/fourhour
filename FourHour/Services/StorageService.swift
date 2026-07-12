import Foundation

final class StorageService {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func saveBudget(_ budget: DailyBudget) {
        guard let data = try? encoder.encode(budget) else { return }
        defaults.set(data, forKey: "budget_\(dateKey(budget.date))")
    }

    func loadBudget(for date: Date) -> DailyBudget? {
        guard let data = defaults.data(forKey: "budget_\(dateKey(date))"),
              let budget = try? decoder.decode(DailyBudget.self, from: data)
        else { return nil }
        return budget
    }

    func saveSummary(_ summary: DaySummary) {
        var summaries = loadAllSummaries()
        summaries.removeAll { dateKey($0.date) == dateKey(summary.date) }
        summaries.append(summary)
        if let data = try? encoder.encode(summaries) {
            defaults.set(data, forKey: "summaries")
        }
    }

    func loadAllSummaries() -> [DaySummary] {
        guard let data = defaults.data(forKey: "summaries"),
              let summaries = try? decoder.decode([DaySummary].self, from: data)
        else { return [] }
        return summaries
    }

    private func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
