import XCTest
@testable import FourHour

final class FourHourTests: XCTestCase {
    func testDailyBudgetInitialState() {
        let budget = DailyBudget(date: Date())
        XCTAssertEqual(budget.deepWorkUsed, 0)
        XCTAssertEqual(budget.remaining, 4 * 3600)
        XCTAssertEqual(budget.progress, 0)
        XCTAssertFalse(budget.isOverBudget)
    }

    func testDailyBudgetTracking() {
        var budget = DailyBudget(date: Date())
        budget.deepWorkUsed = 7200 // 2 hours
        XCTAssertEqual(budget.remaining, 7200)
        XCTAssertEqual(budget.progress, 0.5, accuracy: 0.01)
        XCTAssertFalse(budget.isOverBudget)
    }

    func testDailyBudgetOverBudget() {
        var budget = DailyBudget(date: Date())
        budget.deepWorkUsed = 18000 // 5 hours
        XCTAssertTrue(budget.isOverBudget)
    }

    func testPriorityTaskEisenhower() {
        let task = PriorityTask(
            title: "Deep Work",
            estimatedMinutes: 120,
            quadrant: .notUrgentImportant,
            order: 0
        )
        XCTAssertEqual(task.quadrant, .notUrgentImportant)
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.estimatedMinutes, 120)
    }

    func testFocusSessionDuration() {
        let start = Date()
        let end = start.addingTimeInterval(1500) // 25 minutes
        let session = FocusSession(
            startAt: start,
            endAt: end,
            targetMinutes: 25,
            taskTitle: "Coding",
            interrupted: false
        )
        XCTAssertEqual(session.actualMinutes, 25)
        XCTAssertTrue(session.isComplete)
    }

    func testEnergyLevelOrder() {
        let levels = EnergyLevel.allCases
        XCTAssertEqual(levels.first, .peak)
        XCTAssertEqual(levels.last, .drained)
    }
}
